describe Dynamic::Merge::Setting do
  before(:each) do
    @community = Community.create!(name: 'My', permalink: 'my')
    @schema = @community.schema
    @user = ::User.create!(email: 'contact@kosmopolead.com', login: 'contact@kosmopolead.com')
    @user.memberships.create!(community: @community, admin: true)
    @schema.features.detect {|f| f.name == 'Dynamic::Merge::Feature'}.update!(enabled: true)
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

  context 'with invalid permissions' do
    before(:each) do
      @user.memberships.first.update!(admin: false)
      @role = @community.roles.create!(name: 'CRM user')
      @user.roles << @role
      UneekPermission::Rule.create!(
        schema: @schema,
        receiver: @role,
        permission: '_R__',
        klass_name: 'D::My::R::Merge::Setting',
      )

      @contact1 = D::My::Contact.create!(
        last_name: "Forrest Gump",
      )
      @contact2 = D::My::Contact.create!(
        last_name: "Gump",
        first_name: "Forrest",
      )

      @merge_setting = D::My::R::Merge::Setting.new(
        result_record_type: 'D::My::Contact',
        record_to_merges_attributes: [
          {
            id: @contact1.id,
            type: @contact1.type,
          },
          {
            id: @contact2.id,
            type: @contact2.type,
          },
        ],
        fields_attributes: [
          {
            name: "last_name",
          },
        ],
      )
    end

    it 'should not create merge setting' do
      expect(@merge_setting.can_be_created_by?(@user)).to be false
    end

  end
end
