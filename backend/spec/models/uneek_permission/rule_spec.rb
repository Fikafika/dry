describe UneekPermission::Rule, sidekiq: false do
  before(:each) do
    @user = User.create(login: "Login", email: "email@kosmopolead.com")
    @community = Community.create!(name: 'My', permalink: 'my')
    @schema = @community.schema
    @klass = @schema.klasses.create!(name: 'Klass', attrs_attributes: [{name: 'name', type: 'String'}])
  end

  context 'a rule on klass inheriting DynamicRecord' do

    describe 'create' do

      context 'create permission' do
        before(:each) do
          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: 'C___',
            klass_name: @klass.const_absolute_name,
          )
        end

        it 'should create a matching rule on Dynamic::Form' do
          @rule = UneekPermission::Rule.find_by(klass_name: 'Dynamic::Form', receiver: @user)
          expect(@rule.permission).to eq('_R__')
          expect(@rule.instance.klass_name).to eq(@klass.const_absolute_name)
        end

        it 'should create a matching rule for default input mode' do
          @form_rules = UneekPermission::Rule.where(klass_name: 'Dynamic::Form', receiver: @user).all
          expect(@form_rules.count).to eq(1)
          expect(@form_rules.first.instance.default).to be true
          expect(@form_rules.first.instance.mode).to eq('input')
        end

      end

      context 'read permission' do
        before(:each) do
          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '_R__',
            klass_name: @klass.const_absolute_name,
          )
        end

        it 'should create a matching rule on Dynamic::Form' do
          @rule = UneekPermission::Rule.find_by(klass_name: 'Dynamic::Form', receiver: @user)
          expect(@rule.permission).to eq('_R__')
          expect(@rule.instance.klass_name).to eq(@klass.const_absolute_name)
        end

        it 'should create matching rules for default edit_in_place and read_only mode' do
          @form_rules = UneekPermission::Rule.where(klass_name: 'Dynamic::Form', receiver: @user).all
          expect(@form_rules.count).to eq(2)
          @form_rules.each do |r|
            expect(r.instance.default).to be true
            expect(r.instance.mode).to eq('read_only').or eq('edit_in_place')
          end
        end

      end

      context 'update permission' do
        before(:each) do
          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '__U_',
            klass_name: @klass.const_absolute_name,
          )
        end

        it 'should create a matching rule on Dynamic::Form' do
          @rule = UneekPermission::Rule.find_by(klass_name: 'Dynamic::Form', receiver: @user)
          expect(@rule.permission).to eq('_R__')
          expect(@rule.instance.klass_name).to eq(@klass.const_absolute_name)
        end

        it 'should create a matching rule for default edit_in_place mode' do
          @form_rules = UneekPermission::Rule.where(klass_name: 'Dynamic::Form', receiver: @user).all
          expect(@form_rules.count).to eq(1)
          expect(@form_rules.first.instance.default).to be true
          expect(@form_rules.first.instance.mode).to eq('edit_in_place')
        end

      end

      context 'already existing rule' do
        before(:each) do
          @read_only_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'read_only', default: true)
          @edit_in_place_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'edit_in_place', default: true)

          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '___',
            klass_name: 'Dynamic::Form',
            instance: @read_only_form
          )
          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '___',
            klass_name: 'Dynamic::Form',
            instance: @edit_in_place_form
          )
        end

        it 'should not create a new rule' do
          expect{
            UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              permission: '_R__',
              klass_name: 'D::My::Klass',
            )
          }.to not_change{
            UneekPermission::Rule.where(klass_name: 'Dynamic::Form', receiver: @user).count
          }
        end
      end

      context 'klass with associations' do
        before(:each) do
          @other_klass = @schema.klasses.create!(name: 'OtherKlass', attrs_attributes: [{name: 'name', type: 'String'}])
          @owner_other_klass_assoc = @other_klass.associations.create!(name: 'owner', type: 'BelongsTo')
          @klass.associations.create!(name: 'others', target_klass: @other_klass, type: 'HasMany', inverse_of: @owner_other_klass_assoc)
        end

        context 'create permission' do
          before(:each) do
            UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              permission: 'C___',
              klass_name: @klass.const_absolute_name,
            )
          end

          it 'should not create a matching rule for default input mode through associations' do
            @input_form_through_assoc = Dynamic::Form.find_by(
              klass_name: @other_klass.const_absolute_name,
              association_klass_name: @klass.const_absolute_name,
              target_klass_name: @klass.const_absolute_name,
              default: true,
              mode: 'input'
            )
            expect(UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)).to be false
          end
        end

        context 'update permission' do
          before(:each) do
            UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              permission: '__U_',
              klass_name: @klass.const_absolute_name,
            )
          end

          it 'should create a matching rule for default input mode through associations' do
            @input_form_through_assoc = Dynamic::Form.find_by(
              klass_name: @other_klass.const_absolute_name,
              association_klass_name: @klass.const_absolute_name,
              target_klass_name: @klass.const_absolute_name,
              default: true,
              mode: 'input'
            )
            expect(UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)).to be true
          end
        end

        context 'update permission on a single association' do
          before(:each) do
            @another_klass = @schema.klasses.create!(name: 'AnotherKlass', attrs_attributes: [{name: 'name', type: 'String'}])
            @owner_another_klass_assoc = @another_klass.associations.create!(name: 'owner', type: 'BelongsTo')
            @klass.associations.create!(name: 'anothers', target_klass: @another_klass, type: 'HasMany', inverse_of: @owner_another_klass_assoc)
            UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              permission: '__U_',
              attr: 'others',
              klass_name: @klass.const_absolute_name,
            )
          end

          it 'should create a matching rule for default input mode through targeted association' do
            @input_form_through_assoc = Dynamic::Form.find_by(
              klass_name: @other_klass.const_absolute_name,
              association_klass_name: @klass.const_absolute_name,
              target_klass_name: @klass.const_absolute_name,
              default: true,
              mode: 'input'
            )
            expect(UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)).to be true
          end

          it 'should not create a matching rule for default input mode through others associations' do
            @input_form_through_assoc = Dynamic::Form.find_by(
              klass_name: @another_klass.const_absolute_name,
              association_klass_name: @klass.const_absolute_name,
              target_klass_name: @klass.const_absolute_name,
              default: true,
              mode: 'input'
            )
            expect(UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)).to be false
          end
        end

      end

      context 'existing rule on default input form' do
        before(:each) do
          @default_form = Dynamic::Form.find_by(mode: 'input', default: true, klass_name: @klass.const_absolute_name)
          @form_for_user = Dynamic::Form.create!(
            schema: @schema,
            klass_name: @klass.const_absolute_name,
            mode: 'input',
            default: true
          )
          @rule_form = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '_R__',
            instance: @form_for_user,
            klass_name: 'Dynamic::Form',
          )
        end

        it 'should not create a rule on base default form' do
          expect{
            UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              klass_name: @klass.const_absolute_name,
              permission: 'C___'
            )
          }.to not_change{
            UneekPermission::Rule.exists?(receiver: @user, instance: @rule_form)
          }.and not_change{
            UneekPermission::Rule.exists?(receiver: @user, instance: @default_form)
          }
        end

      end

    end

    describe 'update' do

      context 'from create to update' do
        before(:each) do
          @rule = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: 'C___',
            klass_name: @klass.const_absolute_name,
          )
        end

        it 'should update corresponding form rule' do
          expect{
            @rule.update!(permission: '_R__')
          }.to change{
            UneekPermission::Rule.where(klass_name: 'Dynamic::Form', receiver: @user).map {|r| r.instance.mode}
          }.from(['input']).to(['edit_in_place', 'read_only'])
        end

        it 'should create another rule' do
          expect{
            @rule.update!(permission: '_R__')
          }.to change{
            UneekPermission::Rule.where(klass_name: 'Dynamic::Form', receiver: @user).count
          }.by(1)
        end
      end

      context 'from create and read to update' do
        before(:each) do
          @rule = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: 'CR__',
            klass_name: @klass.const_absolute_name,
          )
        end

        it 'should destroy rule on form being default and having input mode' do
          expect{
            @rule.update!(permission: '__U_')
          }.to change{
            @input_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'input', default: true)
            UneekPermission::Rule.where(klass_name: 'Dynamic::Form', receiver: @user, instance_id: @input_form.id).count
          }.by(-1)
        end

        it 'should keep rule on form being default and having read_only mode' do
          expect{
            @rule.update!(permission: '__U_')
          }.to change{
            @read_only_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'read_only', default: true)
            UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance_id: @read_only_form.id)
          }.from(true).to(false)
        end

        it 'should keep rule on form being default and having edit_in_place mode' do
          expect{
            @rule.update!(permission: '__U_')
          }.to not_change{
            @edit_in_place_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'edit_in_place', default: true)
            UneekPermission::Rule.find_by(klass_name: 'Dynamic::Form', receiver: @user, instance_id: @edit_in_place_form.id).id
          }
        end

      end

      context 'from update to create and read' do
        before(:each) do
          @rule = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '__U_',
            klass_name: @klass.const_absolute_name,
          )
        end

        it 'should create rule on form with input mode' do
          expect{
            @rule.update!(permission: 'CR__')
          }.to change{
            @input_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'input', default: true)
            UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance_id: @input_form.id)
          }.from(false).to(true)
        end

        it 'should keep rule on form being default and having edit_in_place mode' do
          expect{
            @rule.update!(permission: 'CR__')
          }.to not_change{
            @edit_in_place_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'edit_in_place', default: true)
            UneekPermission::Rule.find_by(klass_name: 'Dynamic::Form', receiver: @user, instance_id: @edit_in_place_form.id).id
          }
        end

      end

      context 'from read to create' do
        before(:each) do
          @rule = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '_R__',
            klass_name: @klass.const_absolute_name,
          )
        end

        it 'should not destroy form rules from previous rules' do
          expect{
            @rule.update!(permission: 'C___')
          }.to change{
            @edit_in_place_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'edit_in_place', default: true)
            UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @edit_in_place_form)
          }.from(true).to(false)
        end
      end

      context 'with multiple rules on klass' do
        before(:each) do
          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '__U_',
            klass_name: @klass.const_absolute_name,
          )
          @rule = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '_R__',
            attr: 'name',
            klass_name: @klass.const_absolute_name,
          )
        end

        context 'updating to an action not yet specified' do

          it 'should not destroy form rules from previous rules' do
            expect{
              @rule.update!(permission: 'C___')
            }.to not_change{
              @edit_in_place_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'edit_in_place', default: true)
              UneekPermission::Rule.find_by(klass_name: 'Dynamic::Form', receiver: @user, instance: @edit_in_place_form).id
            }
          end

        end

      end

      context 'klass with associations' do
        before(:each) do
          @other_klass = @schema.klasses.create!(name: 'OtherKlass', attrs_attributes: [{name: 'name', type: 'String'}])
          @owner_other_klass_assoc = @other_klass.associations.create!(name: 'owner', type: 'BelongsTo')
          @klass.associations.create!(name: 'others', target_klass: @other_klass, type: 'HasMany', inverse_of: @owner_other_klass_assoc)
        end

        context 'update to create' do
          before(:each) do
            @rule = UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              permission: '__U_',
              klass_name: @klass.const_absolute_name,
            )
          end

          it 'should create a matching rule for default input mode through associations' do
            expect{
              @rule.update!(grant: 8)
            }.to change{
              @input_form_through_assoc = Dynamic::Form.find_by(
                klass_name: @other_klass.const_absolute_name,
                association_klass_name: @klass.const_absolute_name,
                default: true,
                mode: 'input'
              )
              UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)
            }.from(true).to(false)
          end
        end

        context 'create to update' do
          before(:each) do
            @rule = UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              permission: 'C___',
              klass_name: @klass.const_absolute_name,
            )
          end

          it 'should create a matching rule for default input mode through associations' do
            expect{
              @rule.update!(grant: 2)
            }.to change{
              @input_form_through_assoc = Dynamic::Form.find_by(
                klass_name: @other_klass.const_absolute_name,
                association_klass_name: @klass.const_absolute_name,
                default: true,
                mode: 'input'
              )
              UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)
            }.from(false).to(true)
          end
        end

      end

      context 'existing rule on default input form' do
        before(:each) do
          @default_form = Dynamic::Form.find_by(mode: 'edit_in_place', default: true, klass_name: @klass.const_absolute_name)
          @form_for_user = Dynamic::Form.create!(
            schema: @schema,
            klass_name: @klass.const_absolute_name,
            mode: 'edit_in_place',
            default: true
          )
          @rule_form = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '_R__',
            instance: @form_for_user,
            klass_name: 'Dynamic::Form',
          )
          @rule = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            klass_name: @klass.const_absolute_name,
            permission: '_R__'
          )
        end

        it 'should not create a rule on base default form' do
          expect{
           @rule.update!(grant: 2)
          }.to not_change{
            UneekPermission::Rule.exists?(receiver: @user, instance: @rule_form)
          }.and not_change{
            UneekPermission::Rule.exists?(receiver: @user, instance: @default_form)
          }
        end

      end

    end

    describe 'destroy' do

      context 'create permission' do
        before(:each) do
          @rule = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: 'C___',
            klass_name: @klass.const_absolute_name,
          )
        end

        it 'should destroy a rule on default input form' do
          expect{
            @rule.destroy!
          }.to change{
            @input_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'input', default: true)
            UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form)
          }.from(true).to(false)
        end

      end

      context 'with multiples rules on klass' do
        before(:each) do
          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '__U_',
            klass_name: @klass.const_absolute_name,
          )
          @rule = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '_R__',
            attr: 'name',
            klass_name: @klass.const_absolute_name,
          )
        end

        it 'should not destroy form rules from previous rules' do
          expect{
            @rule.destroy!
          }.to not_change{
            @edit_in_place_form = Dynamic::Form.find_by(klass_name: @klass.const_absolute_name, mode: 'edit_in_place', default: true)
            UneekPermission::Rule.find_by(klass_name: 'Dynamic::Form', receiver: @user, instance: @edit_in_place_form).id
          }
        end

      end

      context 'klass with associations' do
        before(:each) do
          @other_klass = @schema.klasses.create!(name: 'OtherKlass', attrs_attributes: [{name: 'name', type: 'String'}])
          @owner_other_klass_assoc = @other_klass.associations.create!(name: 'owner', type: 'BelongsTo')
          @klass.associations.create!(name: 'others', target_klass: @other_klass, type: 'HasMany', inverse_of: @owner_other_klass_assoc)
        end

        context 'update permission' do
          before(:each) do
            @rule = UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              permission: '__U_',
              klass_name: @klass.const_absolute_name,
            )
          end

          it 'should destroy rule for default input mode through associations' do
            expect{
              @rule.destroy!
            }.to change{
              @input_form_through_assoc = Dynamic::Form.find_by(
                klass_name: @other_klass.const_absolute_name,
                association_klass_name: @klass.const_absolute_name,
                target_klass_name: @klass.const_absolute_name,
                default: true,
                mode: 'input'
              )
              UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)
            }.from(true).to(false)
          end
        end

        context 'update permission on a single association' do
          before(:each) do
            @another_klass = @schema.klasses.create!(name: 'AnotherKlass', attrs_attributes: [{name: 'name', type: 'String'}])
            @owner_another_klass_assoc = @another_klass.associations.create!(name: 'owner', type: 'BelongsTo')
            @klass.associations.create!(name: 'anothers', target_klass: @another_klass, type: 'HasMany', inverse_of: @owner_another_klass_assoc)
            @rule = UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              permission: '__U_',
              attr: 'others',
              klass_name: @klass.const_absolute_name,
            )
          end

          it 'should destroy rule for default input mode through associations' do
            expect{
              @rule.destroy!
            }.to change{
              @input_form_through_assoc = Dynamic::Form.find_by(
                klass_name: @other_klass.const_absolute_name,
                association_klass_name: @klass.const_absolute_name,
                target_klass_name: @klass.const_absolute_name,
                default: true,
                mode: 'input'
              )
              UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)
            }.from(true).to(false)
          end

          it 'should not destroy rule for default input mode through others associations' do
            expect{
              @rule.destroy!
            }.to not_change{
              @input_form_through_assoc = Dynamic::Form.find_by(
                klass_name: @another_klass.const_absolute_name,
                association_klass_name: @klass.const_absolute_name,
                target_klass_name: @klass.const_absolute_name,
                default: true,
                mode: 'input'
              )
              UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)
            }
          end
        end

        context 'rules on klass and association' do
          before(:each) do
            @rule_on_klass = UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              permission: '__U_',
              klass_name: @klass.const_absolute_name,
            )
            @rule_on_assoc = UneekPermission::Rule.create!(
              schema: @schema,
              receiver: @user,
              permission: '__U_',
              attr: 'others',
              klass_name: @klass.const_absolute_name,
            )
          end

          context 'destroying klass one' do
            it 'should not destroy rule for default input mode through associations' do
              expect{
                @rule_on_klass.destroy!
              }.to_not change{
                @input_form_through_assoc = Dynamic::Form.find_by(
                  klass_name: @other_klass.const_absolute_name,
                  association_klass_name: @klass.const_absolute_name,
                  target_klass_name: @klass.const_absolute_name,
                  default: true,
                  mode: 'input'
                )
                UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)
              }
            end
          end

          context 'destroying association one' do
            it 'should not destroy rule for default input mode through associations' do
              expect{
                @rule_on_klass.destroy!
              }.to_not change{
                @input_form_through_assoc = Dynamic::Form.find_by(
                  klass_name: @other_klass.const_absolute_name,
                  association_klass_name: @klass.const_absolute_name,
                  target_klass_name: @klass.const_absolute_name,
                  default: true,
                  mode: 'input'
                )
                UneekPermission::Rule.exists?(klass_name: 'Dynamic::Form', receiver: @user, instance: @input_form_through_assoc)
              }
            end
          end

        end

      end

    end

  end

  context 'invalidating cache' do
    before(:each) do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache.lookup_store(:memory_store))
    end

    after(:each) do
      Rails.cache.clear
    end

    context 'reserved klasses' do
      before(:each) do
        @schema.load
        @const_reserved_name = "#{@schema.const.name}::#{@schema.class::RESERVED_CONSTANT}::"
      end

      context 'for Menu' do
        before(:each) do
          @user.memberships.create!(community: @community)
          Rails.cache.fetch(D::My::R::Menu.first.cache_key_with_version) {'toto'}
        end

        it 'should delete cache key' do
          expect{
            UneekPermission::Rule.create!(
              schema: @schema,
              user_field: 'id',
              instance_field: 'user_id',
              receiver: @user,
              klass_name: @const_reserved_name + 'Menu',
              grant: 15,
            )
          }.to change{
            Rails.cache.read(D::My::R::Menu.first.cache_key_with_version)
          }.from('toto').to(nil)
        end
      end

      context 'for Menu::Item' do
        before(:each) do
          @user.memberships.create!(community: @community)
          Rails.cache.fetch(D::My::R::Menu::Item.first.cache_key_with_version) {'titi'}
        end

        it 'should delete cache key' do
          expect{
            UneekPermission::Rule.create!(
              schema: @schema,
              user_field: 'id',
              instance_field: 'menu.user_id',
              receiver: @user,
              klass_name: @const_reserved_name + 'Menu::Item',
              grant: 15,
            )
          }.to change{
            Rails.cache.read(D::My::R::Menu::Item.first.cache_key_with_version)
          }.from('titi').to(nil)
        end

      end

    end
  end

end