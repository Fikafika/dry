describe 'Form::Editor', type: :system do
  before(:each) do
    page_exec do
      $schema = Dynamic::Schema.new(
        name: 'Uneek',
        klasses: [
          {
            id: 1,
            name: 'Contact',
            translations: [
              {
                human_name: 'Contact',
                locale: 'en',
              },
              {
                human_name: 'Contact',
                locale: 'fr',
              },
            ],
            attrs: [
              {
                id: 1,
                name: 'civility',
                translations: [
                  {
                    human_name: 'Civility',
                    locale: 'en',
                  },
                  {
                    human_name: 'Civilite',
                    locale: 'fr',
                  },
                ],
                values: [{
                  id: 1,
                  name: 'mr',
                  translations: [
                    {
                      human_name: 'Mr',
                      locale: 'en',
                    },
                    {
                      human_name: 'Monsieur',
                      locale: 'fr',
                    },
                  ]
                }, {
                  id: 2,
                  name: 'mrs',
                  translations: [
                    {
                      human_name: 'Mrs',
                      locale: 'en',
                    },
                    {
                      human_name: 'Madame',
                      locale: 'fr',
                    },
                  ]
                }],
                type: 'Enum',
              }
            ],
            associations: [
              {
                id: 1,
                name: 'account',
                target_klass_id: 2,
                type: 'Association::BelongsTo',
                translations: [
                  {
                    human_name: 'account',
                    locale: 'en',
                  },
                  {
                    human_name: 'entreprise',
                    locale: 'fr',
                  },
                ],
              },
              {
                id: 1,
                name: 'emails',
                target_klass_id: 3,
                type: 'Association::HasMany',
                translations: [
                  {
                    human_name: 'e-mails',
                    locale: 'en',
                  },
                  {
                    human_name: 'e-mails',
                    locale: 'fr',
                  },
                ],
              },
            ]
          },
          {
            id: 2,
            name: 'Account',
            translations: [
              {
                human_name: 'Account',
                locale: 'en',
              },
              {
                human_name: 'Account',
                locale: 'fr',
              },
            ],
            attrs: [
              {
                id: 2,
                name: 'name',
                type: 'String',
              }
            ]
          },
          {
            id: 3,
            name: 'Email',
            translations: [
              {
                human_name: 'E-mail',
                locale: 'en',
              },
              {
                human_name: 'E-mail',
                locale: 'fr',
              },
            ],
            attrs: [
              {
                id: 4,
                name: 'address',
                type: 'String',
              }
            ]
          }
        ]
      )
      $schema.status_code = 200 # mark as loaded
      $schema.load_constants
    end
  end

  describe 'enum element' do

    it 'should be displayed' do
      mount do
        $form = Dynamic::Form.new(
          id: 1,
          klass_name: 'D::Uneek::Contact',
          elements: [
            {
              id: 1,
              klass_name: 'D::Uneek::Contact',
              root_klass_name: 'D::Uneek::Contact',
              attribute_name: 'civility',
              type: 'Attribute::Enum',
              editor: 'radio',
            },
          ],
        )
        $form.status_code = 200 # mark as loaded
        Form::Editor(schema: $schema, form: $form)
      end
      expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mr"]')
      expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mrs"]')
    end

    it 'should set default value' do
      mount do
        $form = Dynamic::Form.new(
          id: 1,
          klass_name: 'D::Uneek::Contact',
          elements: [
            {
              id: 1,
              klass_name: 'D::Uneek::Contact',
              root_klass_name: 'D::Uneek::Contact',
              attribute_name: 'civility',
              default_value: 'mrs',
              type: 'Attribute::Enum',
              editor: 'radio',
            },
          ],
        )
        $form.status_code = 200 # mark as loaded
        Form::Editor(schema: $schema, form: $form)
      end
      expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mrs"][checked]')
    end

  end

  describe 'belongs_to element' do

    it 'should be displayed' do
      mount do
        $form = Dynamic::Form.new(
          id: 1,
          klass_name: 'D::Uneek::Contact',
          elements: [
            {
              id: 1,
              klass_name: 'D::Uneek::Contact',
              root_klass_name: 'D::Uneek::Contact',
              attribute_name: 'account',
              type: 'Association::BelongsTo',
            },
          ],
        )
        $form.status_code = 200 # mark as loaded
        Form::Editor(schema: $schema, form: $form)
      end
      expect(page).to have_selector('[name="contact[account]"]')
    end

    xit 'should set default value' do # TODO
      mount do
        $account = D::Uneek::Account.new(id: 1, name: 'Uneek')
        $account.status_code = 200
        D::Uneek::Account.cache[:find][$account.scope] = $account

        $form = Dynamic::Form.new(
          id: 1,
          klass_name: 'D::Uneek::Contact',
          elements: [
            {
              id: 1,
              klass_name: 'D::Uneek::Contact',
              root_klass_name: 'D::Uneek::Contact',
              attribute_name: 'account',
              default_value: 1,
              type: 'Association::BelongsTo',
            },
          ],
        )
        $form.status_code = 200 # mark as loaded
        Form::Editor(schema: $schema, form: $form)
      end
      expect(page).to have_selector('[name="contact[account][value="1"]')
    end

  end

  describe 'has_many element' do

    it 'should be displayed' do
      mount do
        $form = Dynamic::Form.new(
          id: 1,
          klass_name: 'D::Uneek::Contact',
          elements: [
            {
              id: 1,
              klass_name: 'D::Uneek::Contact',
              root_klass_name: 'D::Uneek::Contact',
              attribute_name: 'emails',
              type: 'Association::HasMany',
            },
          ],
        )
        $form.status_code = 200 # mark as loaded
        Form::Editor(schema: $schema, form: $form)
      end
      expect(page).to have_selector('[name="contact[emails][]"]')
    end

  end

  describe 'has_one_attached element' do
    before(:each) do
      page_exec do
        $form = Dynamic::Form.new(
          id: 1,
          klass_name: 'D::Uneek::Contact',
          elements: [
            {
              id: 1,
              klass_name: 'D::Uneek::Contact',
              root_klass_name: 'D::Uneek::Contact',
              attribute_name: 'photo',
              type: 'Attachment::HasOne',
            },
          ],
        )
        $form.status_code = 200 # mark as loaded
      end
    end

    context 'default editor' do

      it 'should be displayed as input file' do
        mount do
          Form::Editor(schema: $schema, form: $form)
        end
        expect(page).to have_selector('input[type="file"]', visible: false)
      end

    end

    context 'photo editor' do
      before(:each) do
        page_exec do
          $form.elements.first.attributes[:editor] = 'photo'
        end
      end

      it 'should be displayed as image' do
        mount do
          Form::Editor(schema: $schema, form: $form)
        end
        expect(page).to have_selector('.photo-button')
        expect(page).to have_selector('input[type="file"]', visible: false)
      end

    end
  end

end


