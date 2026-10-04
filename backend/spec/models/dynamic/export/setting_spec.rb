describe Dynamic::Export::Setting do
  context 'ordered in datatable' do
    before(:each) do
      @community = Community.create!(name: 'My', permalink: 'my')
      @schema = @community.schema
      @user = ::User.create!(email: 'contact@kosmopolead.com', login: 'contact@kosmopolead.com')
      @user.memberships.create!(community: @community, admin: true)
      @schema.features.detect {|f| f.name == 'Dynamic::Export::Feature'}.update!(enabled: true)
      @Contact, @Account = @schema.klasses.create!(
        [
          {
            name: 'Contact',
            attrs_attributes: [
              {
                name: 'first_name',
                type: 'String',
              },
              {
                name: 'last_name',
                type: 'String',
              },
            ],
          },
          {
            name: 'Account',
            attrs_attributes: [
              {
                name: 'Name',
                type: 'String',
              },
            ],
          }
        ],
      )
      company_assoc = @Contact.associations.create!(name: 'company', target_klass: @Account, type: 'BelongsTo')
      employees_assoc = @Account.associations.create!(name: 'employees', target_klass: @Contact, type: 'HasMany', inverse_of: company_assoc)
      company_assoc.update!(inverse_of: employees_assoc)

      @schema.load
    end

    it 'should export ordered contacts by first_name' do
      @contact1 = D::My::Contact.create!(
        first_name: 'Forrest',
        last_name: 'Lo'
      )
      @contact2 = D::My::Contact.create!(
        last_name: 'Gump',
        first_name: 'Lo'
      )
      @export_setting = D::My::R::Export::Setting.create(
        klass_name_to_export: 'D::My::Contact',
        scope_for_records_to_export: {order: {first_name: :asc}},
        export_type: 'csv',
        encoding_type: 'utf-8',
        attrs_to_export: {first_name: 1, last_name: 1}
      )

      expect(@export_setting.record_to_exports).to contain_exactly(@contact1, @contact2)
    end

    context 'with invalid permissions' do
      before(:each) do
        @user.memberships.first.update!(admin: false)
        @role = @community.roles.create!(name: 'CRM user')
        @user.roles << @role
        UneekPermission::Rule.create!(
          schema: @schema,
          receiver: @role,
          permission: '_R__',
          klass_name: 'D::My::R::Export::Setting',
        )
        @export = D::My::R::Export::Setting.new(
          klass_name_to_export: 'D::My::Contact',
          scope_for_records_to_export: {order: {first_name: :asc}},
          export_type: "csv",
          encoding_type: "utf-8",
          attrs_to_export: {first_name: 1, last_name: 1}
        )
      end

      it 'should not create export' do
        expect(@export.can_be_created_by?(@user)).to be false
      end

    end
  end
end
