describe Dynamic::Schema::Klass, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
  end

  describe :CreateDefaultForms do

    describe '.create' do
      it 'should create default forms' do
        expect{
          @schema.klasses.create!(name: 'Klass')
        }.to change{
          @schema.forms.map(&:actions)
        }.by([[:new], [:edit], [:show], [:show]])
      end

      context 'when schema is updated with several new klasses in nested attributes' do
        it 'should create default forms' do
          expect{
            @schema.update(
              klasses_attributes: [
                {
                  name: 'Klass2',
                },
                {
                  name: 'Klass3',
                  attrs_attributes: [{
                    # add an attr in order to cause a crash
                    name: 'attr',
                    type: 'String',
                  }]
                },
              ]
            )
          }.to change{
            @schema.forms.count
          }.by(8)
        end
      end

      context 'a sub class' do
        before(:each) do
          @klass = @schema.klasses.create!(
            name: 'Klass',
            attrs_attributes: [{
              name: 'attr', type: 'String',
            }]
          )
        end

        it 'should contains attributes of super class' do
          @subklass = @schema.klasses.create!(name: 'SubKlass', superklass: @klass)
          @form = @schema.forms.where(klass_name: 'D::My::SubKlass').last
          expect(@form.elements.map(&:attribute_name)).to include('attr')
        end
      end
    end

    context '.form show mode read_only' do
      it 'creates thumbnail form' do
        @schema.klasses.create!(name: 'klass')

        form = @schema.forms.find_by(
          mode: :read_only,
          purpose: 'thumbnail'
        )

        expect(form.actions).to eq([:show])
      end

      it 'creates sheet form' do
        @schema.klasses.create!(name: 'klass')

        form = @schema.forms.find_by(
          mode: :read_only,
          purpose: 'sheet'
        )

        expect(form.actions).to eq([:show])
      end
    end

    describe '.destroy' do
      before(:each) do
        @klass = @schema.klasses.create!(name: 'Klass')
      end
      it 'should create default forms' do
        expect{
          @klass.destroy
        }.to change{
          @schema.forms.count
        }.by(-[[:new], [:edit], [:show], [:show]].length)
      end
    end

  end

  describe :CreateDefaultLayouts do

    describe '.create' do
      it 'should create default layouts' do
        expect{
          @schema.klasses.create!(name: 'Klass')
        }.to change{
          @schema.layouts.map(&:actions)
        }.by([[:index], [:new], [:edit], [:show]])
      end

      it 'should create layout list item for a form thumbnail' do
        @schema.klasses.create!(name: 'klass')
        layout = @schema.layouts.with_actions([:show]).find_by!(klass_name: 'D::My::Klass', purpose: 'thumbnail')

        expect(layout).to be_present
      end

      it 'should create layout sheet' do
        @schema.klasses.create!(name: 'klass')
        layout = @schema.layouts.with_actions([:show]).find_by!(klass_name: 'D::My::Klass', purpose: 'sheet')

        expect(layout).to be_present
      end
    end

    describe '.destroy' do
      before(:each) do
        @klass = @schema.klasses.create!(name: 'Klass')
      end
      it 'should destroy default layouts' do
        expect{
          @klass.destroy
        }.to change{
          @schema.layouts.count
        }.by(-[[:index], [:new], [:edit], [:show]].length)
      end
    end

  end

  describe :Serialization do

    describe '.const.includes_for_variables' do

      before(:each) do
        @schema.unload

        @klass = @schema.klasses.create!(name: 'Klass', attrs_attributes: [{name: 'name', type: 'String'}, {name: 'second_name', type: 'String'}])

        @klass.name_attribute = @klass.attrs.detect {|a| a.name == 'name'}
        @klass.save!

        @klass.attachments.create!(name: 'klass_attachment', type: 'HasOne')

        @associated_klass = @schema.klasses.create!(name: 'AssociationKlass', attrs_attributes: [{name: 'belongs_to_name', type: 'String'}])
        @associated_klass.name_attribute = @associated_klass.attrs.detect {|a| a.name == 'belongs_to_name'}
        @associated_klass.save!

        associated_owner_association = @klass.associations.create!(name: 'associated', target_klass: @associated_klass, type: 'BelongsTo')
        @associated_klass.associations.create!(name: 'klasses', target_klass: @klass, type: 'HasMany', inverse_of: associated_owner_association)

        @many_association_klass = @schema.klasses.create!(name: 'ManyAssociationKlass', attrs_attributes: [{name: 'has_many_name', type: 'String'}])
        @klass.associations.create!(name: 'associateds', target_klass: @many_association_klass, type: 'HasMany')
        @many_association_klass.name_attribute = @many_association_klass.attrs.detect {|a| a.name == 'has_many_name'}
        @many_association_klass.save!

        @many_association_klass.attachments.create!(name: 'assoc_attachment', type: 'HasOne')

        @schema.load
      end

      context "with empty" do
        it "variable array should add 'only' option" do
          expect(D::My::Klass.includes_for_variables([])).to eq({
            "only" =>  ['name'],
            "include" => {}
        }.with_indifferent_access)
        end

        it "string on variable should add 'only' option" do
          expect(D::My::Klass.includes_for_variables([
            ''
          ])).to eq({
            "only" =>  ['name'],
            "include" => {}
          }.with_indifferent_access)
        end
      end

      context "with simple keys" do
        context "take attribute" do
          it "should be added 'only' option" do
            expect(D::My::Klass.includes_for_variables([
              'name'
            ])).to eq({
              "only" =>  ['name'],
              "include" => {}
            }.with_indifferent_access)
          end

          it "should not add non-existent attribute" do
            expect(D::My::Klass.includes_for_variables([
              'name', 'new_attribute'
            ])).to eq({
              "only" =>  ['name'],
              "include" => {}
            }.with_indifferent_access)
          end
        end

        context "with association" do
          context "belongs to" do
            it "should add 'include' option and 'only' for association attribute" do
              expect(D::My::Klass.includes_for_variables([
                'associated.belongs_to_name', 'name'
              ])).to eq({
                "only" => ['name'],
                "include" => {
                  "associated" => {
                    "only" => ["belongs_to_name"],
                    "include" => {}
                  }
                }
              }.with_indifferent_access)
            end
          end

          context "has many" do
            context "with specific item index" do
              it "should add 'include' option and 'only' for association attribute" do
                expect(D::My::Klass.includes_for_variables([
                  'associateds@0.has_many_name', 'name'
                ])).to eq({
                  "only" => ['name'],
                  "include" => {
                    "associateds" => {
                      "only" => ["has_many_name"],
                      "include" => {}
                    }
                  }
                }.with_indifferent_access)
              end
            end

            context "without specific item index" do
              it "should add 'include' option and 'only' for association attribute" do
                expect(D::My::Klass.includes_for_variables([
                  'associateds.has_many_name', 'name'
                ])).to eq({
                  "only" => ['name'],
                  "include" => {
                    "associateds" => {
                      "only" => ["has_many_name"],
                      "include" => {}
                    }
                  }
                }.with_indifferent_access)
              end
            end

            context "without associations field" do

              {
                "and has_many without index" => "associateds",
                "and has_many with index" => "associateds@0"
              }.each do |description, key|
                keys = ['name', 'associated']

                context description do
                  it "should add name_attribute on only" do
                    expect(D::My::Klass.includes_for_variables(keys.push(key))).to eq({
                      "only" => ['name'],
                      "include" => {
                        "associateds" => {
                          "only" => ['has_many_name'],
                          "include" => {}
                        },
                        "associated" => {
                          "only" => ['belongs_to_name'],
                          "include" => {}
                        }
                      }
                    }.with_indifferent_access)
                  end
                end
              end
            end

            context "with invalid attribute" do
              it "should add association with empty include" do
                expect(D::My::Klass.includes_for_variables(['name', 'associateds.invalid_attribute'])).to eq({
                  "only" => ['name'],
                  "include" => {
                    "associateds" => {
                      "only" => ["has_many_name"],
                      "include" => {}
                    }
                  }
                }.with_indifferent_access)
              end
            end
          end

          context "having attachment" do
            it "should add attachment include on association" do
              expect(D::My::Klass.includes_for_variables([
                'name', 'associateds@0.has_many_name', 'associateds@0.assoc_attachment'
              ])).to eq({
                "only" => ['name'],
                "include" => {
                  "associateds" => {
                    "only" => ["has_many_name"],
                    "include" => {
                      "assoc_attachment" => Dynamic::Schema::Attachment::Base.active_storage_includes
                    }
                  }
                }
              }.with_indifferent_access)
            end
          end
        end

        context "with attachment" do
          it "should add attachment on include" do
            expect(D::My::Klass.includes_for_variables([
              'name', 'klass_attachment'
            ])).to eq({
              "only" => ['name'],
              "include" => {
                "klass_attachment" => Dynamic::Schema::Attachment::Base.active_storage_includes
              }
            }.with_indifferent_access)
          end
        end
      end

      context "with nested keys" do
        context "on association" do
          context "attributes" do
            it "should add include on nested association and add 'only' for deepest association attribute" do
              expect(@associated_klass.const.includes_for_variables([
                'klasses@1.name', 'klasses@0.associateds@0.has_many_name', 'belongs_to_name'
              ])).to eq({
                "only" => ["belongs_to_name"],
                "include" => {
                  "klasses" => {
                    "only" => ["name"],
                    "include" => {
                      "associateds" => {
                        "only" => ["has_many_name"],
                        "include" => {}
                      }
                    }
                  }
                }
              }.with_indifferent_access)
            end
          end

          context "attachments" do
            it "should add include on nested association and add attachment include" do
              expect(@associated_klass.const.includes_for_variables([
                'belongs_to_name', 'klasses@1.name', 'klasses@0.associateds@0.assoc_attachment'
              ])).to eq({
                "only" => ["belongs_to_name"],
                "include" => {
                  "klasses" => {
                    "only" => ["name"],
                    "include" => {
                      "associateds" => {
                        "only" => ["has_many_name"],
                        "include" => {
                          "assoc_attachment" => Dynamic::Schema::Attachment::Base.active_storage_includes
                        }
                      }
                    }
                  }
                }
              }.with_indifferent_access)
            end
          end
        end

      end
    end
  end

  describe :NameAttribute do
    context 'of sub class' do
      before(:each) do
        @schema.klasses.create!(
          id: '019c8ed2-1aa0-7c59-aad1-5d49e7ddf63d',
          name: 'Klass',
          name_attribute_id: '019c8ed1-8e00-72aa-8c9f-8908a733e4d1',
          attrs_attributes: [
            {
              id: '019c8ed1-8e00-72aa-8c9f-8908a733e4d1',
              name: 'name',
              type: 'String',
            }
          ]
        )

        @schema.klasses.create!(
          id: '019c8ed2-a358-73c5-80e6-3981aac806dd',
          superklass_id: '019c8ed2-1aa0-7c59-aad1-5d49e7ddf63d',
          name: 'SubKlass',
        )

        @schema.klasses.create!(
          id: '019c8ed4-2de0-7f08-818a-294b679cf468',
          superklass_id: '019c8ed2-a358-73c5-80e6-3981aac806dd',
          name: 'SubSubKlass',
        )

        @schema.load
      end

      it 'should be inherited from superklass' do
        expect(D::My::Klass.name_attribute).to eq 'name'
        expect(D::My::SubKlass.name_attribute).to eq 'name'
        expect(D::My::SubSubKlass.name_attribute).to eq 'name'
      end
    end
  end

  describe 'CountRecords' do
    before(:each) do
      @klass = @schema.klasses.create!(name: 'Contact')
      @schema.load
    end

    it 'should return number of records' do
      expect{
        D::My::Contact.create!
      }.to change {
        @klass.count_records
      }.from(0).to(1)
    end
  end
end
