describe 'Form::Editor::Panel::Attribute::Enum', type: :system do
  before(:each) do
    page_exec do
      $schema = Dynamic::Schema.new(
        id: 1,
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
          },
        ]
      )
      $schema.status_code = 200 # mark as loaded
      $schema.load_constants

      $get_response = {
        status: 200,
        body: {
          id: 1,
          klass_name: 'D::Uneek::Contact',
          schema_id: 1,
          elements: [
            {
              id: 1,
              klass_name: 'D::Uneek::Contact',
              root_klass_name: 'D::Uneek::Contact',
              attribute_name: 'civility',
              type: 'Attribute::Enum',
              editor: 'radio',
              possible_values: [],
              updated_at: '2023-06-12T14:49:54-0000',
            },
          ],
        }.to_json,
      }

      stub_request(:get, /\/api\/dynamic\/schemas\/uneek\/forms\/1\.json/).to_return do |request|
        $get_response
      end
    end

    mount do
      Form::Editor(schema: $schema, schema_id: 'uneek', form_id: 1)
    end

    find('[data-element-id="1"]').click
  end

  it 'should display' do
    expect(page).to have_css('.form-editor-element-editor')
  end

  it 'should display an widget for edit possible values' do
    expect(page).to have_css('[for="input-attribute-possible_values-"]', visible: false)
  end

  describe 'possible values' do

    context 'add a first possible value' do
      before(:each) do
        find('.btn', text: 'Valeurs possibles').click
        find('.form-editor-element-editor .btn[href="#add"]').click # TODO css selector should be more precise
        find('input[name="attribute[possible_values_attributes][0][text_fr]"]').set('Mademoiselle') # fill label
        find('select[name="attribute[possible_values_attributes][0][value]"] option[value="mrs"]').select_option # select mrs
      end

      xit 'replace enum values by this value in central panel' do # why it doesn't work anymore
        expect(page).to have_css('.form-editor-center-panel label', text: "Mademoiselle")
      end

      context 'save' do
        before(:each) do
          page_exec do
            stub_request(:patch, '/api/dynamic/schemas/uneek/forms/1.json').to_return do |request|
              $patch_body = JSON.parse(request.body)
              { status: 200 }
            end
            $get_response = { # response of form.reload
              status: 200,
              body: {
                id: 1,
                klass_name: 'D::Uneek::Contact',
                schema_id: 1,
                elements: [
                  {
                    id: 1,
                    klass_name: 'D::Uneek::Contact',
                    root_klass_name: 'D::Uneek::Contact',
                    attribute_name: 'civility',
                    type: 'Attribute::Enum',
                    editor: 'radio',
                    possible_values: [
                      {
                        id: 1,
                        position: 0,
                        value: 'mrs',
                        translations: [
                          {
                            text: 'Mademoiselle',
                            locale: 'fr'
                          }
                        ],
                      }
                    ],
                    updated_at: '2023-06-12T14:49:54-0001',
                  },
                ],
              }.to_json,
            }
          end
          find('.btn-primary', text: 'Enregistrer').click
        end

        it 'should update form with possible values' do
          expect(
            page_eval do
              $patch_body.dig('form','elements_attributes', 0, 'possible_values_attributes', 0, 'value') == 'mrs'
            end
          ).to eq true

          expect(page).to_not have_css('.form-editor-center-panel label', text: 'Monsieur')
          expect(page).to have_css('.form-editor-center-panel label', text: "Mademoiselle")
        end

        it 'should not create duplicate possible values when saved again' do
          find('input[name="attribute[possible_values_attributes][0][text_fr]"]').set('Madame')

          page_exec do
            $get_response = { # response of form.reload 2
              status: 200,
              body: {
                id: 1,
                klass_name: 'D::Uneek::Contact',
                schema_id: 1,
                elements: [
                  {
                    id: 1,
                    klass_name: 'D::Uneek::Contact',
                    root_klass_name: 'D::Uneek::Contact',
                    attribute_name: 'civility',
                    type: 'Attribute::Enum',
                    editor: 'radio',
                    possible_values: [
                      {
                        id: 1,
                        position: 0,
                        value: 'mrs',
                        translations: [
                          {
                            text: 'Madame',
                            locale: 'fr'
                          }
                        ],
                      }
                    ],
                    updated_at: '2023-06-12T14:49:54-0002',
                  },
                ],
              }.to_json,
            }
          end

          find('.btn-primary', text: 'Enregistrer').click

          expect(page_eval do
            $patch_body.dig('form','elements_attributes', 0, 'possible_values_attributes')&.length == 1
          end).to eq true

          expect(page_eval do
            $patch_body.dig('form','elements_attributes', 0, 'possible_values_attributes', 0, 'id') == 1
          end).to eq true # because if not provided, it creates a new one
        end

      end
    end

  end

end
