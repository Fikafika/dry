describe 'Form::Editor::Panel::Association::BelongsTo', type: :system do
  [
    {mode: 'input'},
    {mode: 'nested_form'},
  ].each do |params|
    context "mode = #{params[:mode]}" do
      before(:each) do
        page_exec("$mode = '#{params[:mode]}'")
        page_exec do
          $schema = Dynamic::Schema.new(
            id: 1,
            name: 'Uneek',
            klasses: [
              {
                id: 1,
                baseklass_id: 1,
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
                attrs: [],
                associations: [
                  {
                    id: 1,
                    name: 'company',
                    target_klass_id: 2,
                    type: 'Association::BelongsTo',
                    translations: [
                      {
                        human_name: 'Company',
                        locale: 'en',
                      },
                      {
                        human_name: 'Entreprise',
                        locale: 'fr',
                      },
                    ],
                  },
                ],
              },
              {
                id: 2,
                baseklass_id: 2,
                name: 'Account',
                translations: [
                  {
                    human_name: 'Account',
                    locale: 'en',
                  },
                  {
                    human_name: 'Compte',
                    locale: 'fr',
                  },
                ],
                attrs: [
                  {
                    id: 1,
                    name: 'name',
                    type: 'String',
                  },
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
                  attribute_name: 'company',
                  type: 'Association::BelongsTo',
                  mode: $mode,
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

      if params[:mode] == 'nested_form'
        it 'should not display the filters section' do
          expect(page).to have_css('.form-editor-element-editor label', text: 'Condition')
          expect(page).not_to have_css('.form-editor-element-editor .btn', text: 'Filtres')
        end
      else
        it 'should display the filters editor' do
          find('.btn', text: 'Filtres').click
          expect(page).to have_css('.form-editor-element-editor label', text: 'Filtrage de la recherche')
        end
      end
    end
  end
end
