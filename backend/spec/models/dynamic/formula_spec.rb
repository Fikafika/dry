describe Dynamic::Formula do

  describe 'model_dependency' do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
      expect(@schema.features.map(&:name)).to include('Dynamic::Formula::Feature', 'Dynamic::Elasticsearch::Feature')
    end

    context 'record dependent of itself' do

      context 'enum' do
        before(:each) do
          @Klass = @schema.klasses.create!(
            name: 'Klass',
            skip_create_default_layouts: true,
            skip_create_default_forms: true,
            attrs_attributes: [{
              name: 'attr',
              type: 'Enum',
              values_attributes: [{name: 'A'}, {name: 'B'}]
            },{
              name: 'computed_attr',
              formula: 'associated.attr',
              type: 'Enum',
              values_attributes: [{name: 'A'}, {name: 'B'}]
            }],
            associations_attributes: [{
              name: 'associated',
              type: 'BelongsTo',
            }]
          )

          @DependentKlass = @schema.klasses.create!(
            name: 'DependentKlass',
            skip_create_default_layouts: true,
            skip_create_default_forms: true,
            attrs_attributes: [{
              name: 'attr',
              type: 'Enum',
              values_attributes: [{name: 'A'}, {name: 'B'}]
            },{
              name: 'computed_attr',
              formula: 'associated.attr',
              type: 'Enum',
              values_attributes: [{name: 'A'}, {name: 'B'}]
            }],
            associations_attributes: [{
              name: 'associated',
              target_klass: @Klass,
              type: 'BelongsTo',
            }]
          )

          @Klass.associations.first.update(target_klass: @DependentKlass)

          @schema.load
        end

        it 'should not do infinite loop' do
          a = D::My::Klass.create!(attr: 'A')
          b = D::My::DependentKlass.create!(attr: 'B')
          expect{
            Dynamic::Elasticsearch.wait_for_complete do
              a.update!(associated: b)
              b.update!(associated: a)
            end
          }.to change {
            b.class.find(b.id).computed_attr
          }.from(nil).to('A').and change {
            a.class.find(a.id).computed_attr
          }.from(nil).to('B')
        end

        context 'invalid record' do
          before(:each) do
            a = D::My::Klass.create!(attr: 'A')
            b = D::My::DependentKlass.create!(attr: 'B')
            Dynamic::Elasticsearch.wait_for_complete do
              a.update!(associated: b)
              b.update!(associated: a)
            end

            @DependentKlass.attrs.detect{|a| a.name == 'computed_attr'}.values.destroy_all # remove enum value in order to make
            @schema.load

            expect(D::My::DependentKlass.find(b.id).computed_attr).to eq(nil)
          end

          it 'should not do infinite loop' do
            a = D::My::Klass.where(attr: 'A').first
            b = D::My::DependentKlass.where(attr: 'B').first

            Dynamic::Elasticsearch.wait_for_complete do
              b.compute_dependent_records
            end
          end
        end

      end

      context 'date' do
        before(:each) do
          @Klass = @schema.klasses.create!(
            name: 'Klass',
            skip_create_default_layouts: true,
            skip_create_default_forms: true,
            attrs_attributes: [{
              name: 'attr',
              type: 'Date',
            },{
              name: 'computed_attr',
              formula: 'associated.attr',
              type: 'Date',
            }],
            associations_attributes: [{
              name: 'associated',
              type: 'BelongsTo',
            }]
          )

          @DependentKlass = @schema.klasses.create!(
            name: 'DependentKlass',
            skip_create_default_layouts: true,
            skip_create_default_forms: true,
            attrs_attributes: [{
              name: 'attr',
              type: 'Date',
            },{
              name: 'computed_attr',
              formula: 'associated.attr + 30',
              type: 'Date',
            }],
            associations_attributes: [{
              name: 'associated',
              target_klass: @Klass,
              type: 'BelongsTo',
            }]
          )

          @Klass.associations.first.update(target_klass: @DependentKlass)

          @schema.load
        end

        it 'record with missing date should not do infinite loop' do
          a = D::My::Klass.create!
          b = D::My::DependentKlass.create!
          Dynamic::Elasticsearch.wait_for_complete do
            a.update!(associated: b)
            b.update!(associated: a)
          end
          expect(D::My::DependentKlass.find(b.id).computed_attr).to eq(nil)
        end

      end

      context 'belongs_to inverse_of has_many' do
        before(:each) do
          @DependentKlass = @schema.klasses.create!(
            name: 'DependentKlass',
            skip_create_default_layouts: true,
            skip_create_default_forms: true,
          )

          @Klass = @schema.klasses.create!(
            name: 'Klass',
            skip_create_default_layouts: true,
            skip_create_default_forms: true,
            attrs_attributes: [{
              name: 'computed_attr',
              formula: 'count(associateds)',
              type: 'Integer',
            }]
          )

          @has_many = @Klass.associations.create!(
            name: 'associateds',
            target_klass: @DependentKlass,
            type: 'HasMany',
          )

          @belongs_to = @DependentKlass.associations.create!(
            name: 'associated',
            target_klass: @Klass,
            type: 'BelongsTo',
          )

          @has_many.update(inverse_of: @belongs_to)
          @belongs_to.update(inverse_of: @has_many)

          @Klass.update(
            options_for_indexed_json: {
              only: ['computed_attr']
            }
          )

          @schema.load
        end

        it 'create associated records should recompute and reindex record' do
          a = nil
          Dynamic::Elasticsearch.wait_for_complete do
            a = D::My::Klass.create!
          end
          expect(a.reload.computed_attr).to eq(0)
          expect(a.__opensearch__.source['computed_attr']).to eq(0)

          Dynamic::Elasticsearch.wait_for_complete do
            D::My::DependentKlass.create!(associated: a)
            D::My::DependentKlass.create!(associated: a)
            D::My::DependentKlass.create!(associated: a)
          end
          expect(a.reload.computed_attr).to eq(3)
          expect(a.__opensearch__.source['computed_attr']).to eq(3)
        end

        it 'change belongs_to should recompte and reindex record' do
          a1 = nil
          a2 = nil
          b = nil
          Dynamic::Elasticsearch.wait_for_complete do
            a1 = D::My::Klass.create!
            a2 = D::My::Klass.create!
            b = D::My::DependentKlass.create!(associated: a1)
          end
          expect(a1.reload.computed_attr).to eq(1)
          expect(a1.__opensearch__.source['computed_attr']).to eq(1)
          expect(a2.reload.computed_attr).to eq(0)
          expect(a2.__opensearch__.source['computed_attr']).to eq(0)
          Dynamic::Elasticsearch.wait_for_complete do
            b.update(associated: a2)
          end
          expect(a1.reload.computed_attr).to eq(0)
          expect(a1.__opensearch__.source['computed_attr']).to eq(0)
          expect(a2.reload.computed_attr).to eq(1)
          expect(a2.__opensearch__.source['computed_attr']).to eq(1)
        end
      end

    end

    context 'indexed records dependent of computed attribute on another record that is dependent of them' do # it combines formula + elasticearch dependencies
      context 'example 1' do
        before(:each) do
          @Email = @schema.klasses.create!(
            name: 'Email',
            attrs_attributes: [{
              name: 'address',
              type: 'String',
            }],
            associations_attributes: [{
              name: 'owner',
              type: 'BelongsTo',
            }]
          )

          @Contact = @schema.klasses.create!(
            name: 'Contact',
            attrs_attributes: [{
              name: 'count_emails',
              formula: 'count(emails)',
              type: 'Integer',
            }],
            associations_attributes: [{
              name: 'emails',
              type: 'HasMany',
              target_klass: @Email,
            }]
          )

          @Contact.associations.find_by(name: 'emails').update(inverse_of: @Email.associations.find_by(name: 'owner'))

          @Contact.update(
            options_for_indexed_json: {
              only: ['count_emails'],
            }
          )

          @schema.load
        end

        context 'create' do
          before(:each) do
            Dynamic::Elasticsearch.wait_for_complete do
              @contact = D::My::Contact.create!
            end
            wait_for_sidekiq2
            expect(@contact.__opensearch__.source['count_emails']).to eq 0
          end

          it 'should properly index' do
            Dynamic::Elasticsearch.wait_for_complete do
              D::My::Email.create!(address: 'test@test.fr', owner_id: @contact.id, owner_type: @contact.class.name)
            end
            wait_for_sidekiq2
            @contact.reload

            expect(@contact.__opensearch__.source['count_emails']).to eq 1
          end

          it 'through association should properly index' do
            Dynamic::Elasticsearch.wait_for_complete do
              @contact.emails.create!(address: 'test@test.fr')
            end
            wait_for_sidekiq2
            @contact.reload
            expect(@contact.__opensearch__.source['count_emails']).to eq 1
          end

        end

        context 'create record and associated record at same' do
          before(:each) do
            Dynamic::Elasticsearch.wait_for_complete do
              @contact = D::My::Contact.create!(
                emails_attributes: [{address: 'test@test.fr'}]
              )
            end
            wait_for_sidekiq2

            @contact.reload
          end

          it 'should properly index' do
            expect(@contact.__opensearch__.source['count_emails']).to eq 1
          end
        end

        context 'update' do
          before(:each) do
            Dynamic::Elasticsearch.wait_for_complete do
              @contact = D::My::Contact.create!
            end
            wait_for_sidekiq2
            expect(@contact.__opensearch__.source['count_emails']).to eq 0

            Dynamic::Elasticsearch.wait_for_complete do
              @contact.update(
                emails_attributes: [{address: 'test@test.fr'}]
              )
            end
            wait_for_sidekiq2

            @contact.reload
          end

          it 'should properly index' do
            expect(@contact.__opensearch__.source['count_emails']).to eq 1
          end
        end

        context 'update with existing records' do
          before(:each) do
            Dynamic::Elasticsearch.wait_for_complete do
              @contact = D::My::Contact.create!
              @email = D::My::Email.create!(address: 'test@test.fr')
            end
            wait_for_sidekiq2
            expect(@contact.__opensearch__.source['count_emails']).to eq 0

            Dynamic::Elasticsearch.wait_for_complete do
              @contact.update(
                emails_attributes: [
                  {id: @email.id},
                ]
              )
            end
            wait_for_sidekiq2

            @contact.reload
          end

          it 'should properly index' do
            expect(@contact.__opensearch__.source['count_emails']).to eq 1
          end
        end

        context 'update with _destroy: true' do
          before(:each) do
            Dynamic::Elasticsearch.wait_for_complete do
              @email = D::My::Email.create!(address: 'test@test.fr')
              @contact = D::My::Contact.create!(emails: [@email])
            end
            wait_for_sidekiq2
            expect(@contact.__opensearch__.source['count_emails']).to eq 1

            Dynamic::Elasticsearch.wait_for_complete do
              @contact.update(
                emails_attributes: [
                  {id: @email.id, _destroy: true},
                ]
              )
            end
            wait_for_sidekiq2

            @contact.reload

            expect(@contact.emails.count).to eq 0
          end

          it 'should properly index' do
            expect(@contact.__opensearch__.source['count_emails']).to eq 0
          end
        end

        context 'destroy associated record' do
          before(:each) do
            Dynamic::Elasticsearch.wait_for_complete do
              @email = D::My::Email.create!(address: 'test@test.fr')
              @contact = D::My::Contact.create!(emails: [@email])
            end
            wait_for_sidekiq2
            expect(@contact.__opensearch__.source['count_emails']).to eq 1

            Dynamic::Elasticsearch.wait_for_complete do
              @email.destroy
            end
            wait_for_sidekiq2

            @contact.reload

            expect(@contact.emails.count).to eq 0
          end

          it 'should properly index' do
            expect(@contact.__opensearch__.source['count_emails']).to eq 0
          end
        end

        context 'remove associated record' do
          before(:each) do
            Dynamic::Elasticsearch.wait_for_complete do
              @email = D::My::Email.create!(address: 'test@test.fr')
              @contact = D::My::Contact.create!(emails: [@email])
            end
            wait_for_sidekiq2
            expect(@contact.__opensearch__.source['count_emails']).to eq 1

            Dynamic::Elasticsearch.wait_for_complete do
              @contact.update(email_ids: [])
            end
            wait_for_sidekiq2

            @contact.reload

            expect(@contact.emails.count).to eq 0
          end

          it 'should properly index' do
            expect(@contact.__opensearch__.source['count_emails']).to eq 0
          end
        end

      end

      context 'example 2' do
        before(:each) do
          @OrderEntry = @schema.klasses.create!(
            name: 'OrderEntry',
            attrs_attributes: [{
              name: 'amount',
              type: 'Float',
            }],
            associations_attributes: [{
              name: 'order',
              type: 'BelongsTo',
            }]
          )

          @Order = @schema.klasses.create!(
            name: 'Order',
            attrs_attributes: [{
              name: 'name',
              type: 'String',
            }, {
              name: 'total',
              formula: 'sum(entries.amount)',
              type: 'Float',
            }],
            associations_attributes: [{
              name: 'entries',
              target_klass: @OrderEntry,
              type: 'HasMany',
            }]
          )

          @OrderEntry_order = @OrderEntry.associations.first
          @Order_entries = @Order.associations.first
          @OrderEntry_order.update(target_klass: @Order, inverse_of: @Order_entries)
          @Order_entries.update(target_klass: @OrderEntry, inverse_of: @OrderEntry_order)

          @OrderEntry.update(
            options_for_indexed_json: {
              only: ['amount'],
              include: {
                order: {
                  only: ['name', 'total'],
                }
              }
            }
          )

          @schema.load
        end

        context 'create' do
          before(:each) do
            Dynamic::Elasticsearch.wait_for_complete do
              @order = D::My::Order.create!(name: 'A')
            end
            wait_for_sidekiq2 # because additional jobs are created in wait_for_complete

            @nb_entries = 25 # high enough in order to trigger a race condition
            @amount = 1.0
            Dynamic::Elasticsearch.wait_for_complete do
              ::ModelDependency.with_dependencies_computed_later do
                @nb_entries.times do
                  D::My::OrderEntry.create!(amount: @amount, order_id: @order.id)
                end
              end
            end
            wait_for_sidekiq2 # because additional jobs are created in wait_for_complete

            @expected_total = @nb_entries * @amount
          end

          it 'should properly index' do
            expect(@order.reload.total).to eq @expected_total
            expect(D::My::OrderEntry.all.map{|e| e.__opensearch__.source}.uniq).to eq([{
              'amount' => @amount,
              'order' => {
                'name' => 'A',
                'total' => @expected_total,
              }
            }])
          end
        end

        context 'update' do
          before(:each) do
            @nb_entries = 15
            @amount = 1.0
            Dynamic::Elasticsearch.wait_for_complete do
              @order = D::My::Order.create!(name: 'A')
              ::ModelDependency.with_dependencies_computed_later do
                @nb_entries.times do
                  D::My::OrderEntry.create!(order_id: @order.id)
                end
              end
            end
            expect(@order.reload.total).to eq 0.0
            @entries = D::My::OrderEntry.where(order_id: @order.id).all
            @expected_total = @nb_entries * @amount
            wait_for_sidekiq2
          end

          it 'should properly index' do # TODO make this test pass because some records are not properly reindexed in production
            Dynamic::Elasticsearch.wait_for_complete do
              ::ModelDependency.with_dependencies_computed_later do
                @entries.each do |e|
                  e.update(amount: @amount)
                end
              end
            end
            wait_for_sidekiq2

            expect(@order.reload.total).to eq @expected_total
            expect(@entries.map{|e| e.reload.__opensearch__.source}.uniq).to eq([{
              'amount' => @amount,
              'order' => {
                'name' => 'A',
                'total' => @expected_total,
              }
            }])
          end

          it 'should properly index 2' do # to be sure it is not a bug in dependency declarations
            expect {
              Dynamic::Elasticsearch.wait_for_complete do
                @order.update!(name: 'B')
              end
              wait_for_sidekiq2
            }.to change {
              @entries[0].reload.__opensearch__.source.dig('order', 'name')
            }.to('B')
          end
        end
      end
    end

  end

end

