# => {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"civility"=>{"equal"=>"Mr."}}]}]}, {"or"=>[{"and"=>[{"name"=>{"contains"=>"biz"}}]}]}]}]}
# => {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"company"=>{"contains_id"=>"018c682f-85c4-7122-82fb-d2d23c57b659"}}]}]}, {"or"=>[{"and"=>[{"addresses[]"=>{"contains_id"=>"018c682f-7aae-73c9-bce6-27f15bb6e50c"}}]}]}]}]}
# => {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"translatable_string"=>{"contains"=>"bitro"}}, {"translatable_string"=>{"ends_with"=>"gog"}}]}]}]}, {"and"=>[{"or"=>[{"and"=>[{"civility"=>{"equal"=>"Mrs."}}]}]}]}]}
# => {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"name"=>{"contains"=>{"variable"=>"addresses.street"}}}]}]}]}]}
# => {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"civility"=>{"equal"=>"Mrs."}}]}]}, {"or"=>[{"and"=>[{"gender"=>{"equal"=>"Female"}}]}]}]}]}

describe 'Form::Element::Layout::Condition', type: :system do
  before(:each) do
    page_exec do
      class Record < HyperResource::Base
      end
    end
  end

  describe 'rendering with condition_formula' do
    before(:each) do
      page_exec do
        class Contact < HyperResource::Base
          attribute :first_name, type: String
          attribute :last_name, type: String
          attribute :middle_name, type: String
          attribute :nick_name, type: String
          attribute :civility, type: Integer
          enum(civility: ['mr', 'mrs'])

          belongs_to :company, class_name: 'Record'
          has_many :addresses, class_name: 'Record'
        end
      end
    end

    context 'when condition is used on element type nested-form' do
      before(:each) do
        page_exec do
          $dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Contact',
            elements: [
              {
                id: 0,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'company',
                editor: 'radio',
                normalized_input_prefix: 'contact@0',
                type: 'Association::BelongsTo',
                value_position: 'right',
                inline: true,
                possible_values: [
                  {
                    value_record: {
                      id: '018c682e-492c-70f2-bac2-90c2b64ad291',
                      type: 'Record',
                      name: 'Toto',
                    },
                    translations: [{
                      text: 'A',
                      locale: 'fr',
                    }],
                    position: 0,
                  },
                  {
                    value_record: {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300e',
                      type: 'Record',
                      name: 'Titi',
                    },
                    translations: [{
                      text: 'B',
                      locale: 'fr',
                    }],
                    position: 1,
                  },
                ],
              },
              {
                id: 1,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'addresses',
                normalized_input_prefix: 'record@0',
                type: 'Association::HasMany',
              },
              {
                id: 2,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"company"=>{"contains_id"=>"018c682e-492c-70f2-bac2-90c2b64ad291"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                type: 'Layout::Condition',
              },
              {
                id: 3,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'first_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
                parent_id: 2,
              },
              {
                id: 4,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"addresses"=>{"contains_id"=>"17ad7795e-9899-47a9-a38f-6c1ead61991b"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                type: 'Layout::Condition',
              },
              {
                id: 5,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'last_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
                parent_id: 4,
              },
              {
                id: 6,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'company',
                normalized_input_prefix: 'contact@0',
                mode: 'nested_form',
                type: 'Association::BelongsTo',
              },
              {
                id: 7,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"company"=>{"contains_id"=>"018c682e-492c-70f2-bac2-90c2b64ad291"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                parent_id: 6,
                type: 'Layout::Condition',
              },
              {
                id: 8,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: ['company'],
                normalized_input_prefix: 'contact@0.company@0',
                attribute_name: 'name',
                parent_id: 7,
                type: 'Attribute::String',
              },
              {
                id: 9,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"addresses"=>{"contains_id"=>"17ad7795e-9899-47a9-a38f-6c1ead61991b"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                parent_id: 6,
                type: 'Layout::Condition',
              },
              {
                id: 10,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: ['company'],
                normalized_input_prefix: 'contact@0.company@0',
                attribute_name: 'sociale',
                parent_id: 9,
                type: 'Attribute::String',
              }
            ],
            serialized_record_for_input_prefix: {},
          )
          $dynamic_form.status_code = 200
        end
      end

      context 'when condition on nested-form fulfilled' do
        before(:each) do
          page_exec do
            $dynamic_form.serialized_record_for_input_prefix = {
              'contact@0': {
                first_name: 'david',
                last_name: 'became',
              },
              'contact@0.company@0': {
                id: '018c682e-492c-70f2-bac2-90c2b64ad291'
              },
              'record@0.addresses@0': {
                id: '17ad7795e-9899-47a9-a38f-6c1ead61991b', name: '3379 Passage Joliot Curie'
              }
            }
          end

          mount do
            Form(dynamic_form: $dynamic_form)
          end
        end

        context "when elements under condition are outside of the nested form" do
          it 'renders the first name element when the company_id is 018c682e-492c-70f2-bac2-90c2b64ad291' do
            expect(page).to have_selector('input[type="text"][name="contact[first_name]"][value="david"]')
          end

          it 'renders the last name element when the addresses_id is 17ad7795e-9899-47a9-a38f-6c1ead61991b' do
            expect(page).to have_selector('input[type="text"][name="contact[last_name]"][value="became"]')
          end
        end

        context "when elements under condition are inside the nested form" do
          it 'renders the company name element when the company_id is 018c682e-492c-70f2-bac2-90c2b64ad291' do
            expect(page).to have_selector('input[type="text"][name="contact.company@0[name]"]')
          end

          it 'renders the company sociale element when the addresses_id is 17ad7795e-9899-47a9-a38f-6c1ead61991b' do
            expect(page).to have_selector('input[type="text"][name="contact.company@0[sociale]"]')
          end
        end
      end

      context 'when condition on nested-form not fulfilled' do
        before(:each) do
          page_exec do
            $dynamic_form.serialized_record_for_input_prefix = {
              'contact@0': {
                first_name: 'david',
                last_name: 'became',
              },
              'contact@0.company@0': {
                id: 'fake-id-to',
              },
              'record@0.addresses@0': {
                id: 'fake-id-to', name: '3379 Passage Joliot Curie'
              }
            }
          end

          mount do
            Form(dynamic_form: $dynamic_form)
          end
        end

        context "when elements under condition are outside of the nested form" do
          it 'does not renders the first name element when the company_id is not 018c682e-492c-70f2-bac2-90c2b64ad291' do
            expect(page).not_to have_selector('input[type="text"][name="contact[first_name]"][value="david"]')
          end

          it 'does not renders the last name element when the addresses_id is not 17ad7795e-9899-47a9-a38f-6c1ead61991b' do
            expect(page).not_to have_selector('input[type="text"][name="contact[last_name]"][value="became"]')
          end
        end

        context "when elements under condition are inside the nested form" do
          it 'does not renders the company name element when the company_id is not 018c682e-492c-70f2-bac2-90c2b64ad291' do
            expect(page).not_to have_selector('input[type="text"][name="contact.company@0[name]"]')
          end

          it 'does not renders the company sociale element when the addresses_id is not 17ad7795e-9899-47a9-a38f-6c1ead61991b' do
            expect(page).not_to have_selector('input[type="text"][name="contact.company@0[sociale]"]')
          end
        end
      end
    end

    context 'condition fulfilled' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Contact',
            elements: [
              {
                id: 0,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'addresses',
                mode: nil,
                normalized_input_prefix: 'record@0',
                type: 'Association::HasMany',
              },
              {
                id: 1,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'first_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
              {
                id: 2,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"first_name"=>{"contains"=>"david"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                type: 'Layout::Condition',
              },
              {
                id: 3,
                parent_id: 2,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'last_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
              {
                id: 4,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'middle_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
              {
                id: 5,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"middle_name"=>{"equal"=>"youzou"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                type: 'Layout::Condition',
              },
              {
                id: 6,
                parent_id: 5,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'nick_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
              {
                id: 7,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'civility',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::Enum',
                editor: 'radio',
              },
              {
                id: 8,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                #civility equal Mr. and first_name contain david
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"civility"=>{"equal"=>"mrs"}}]}]},{"or"=>[{"and"=>[{"first_name"=>{"contains"=>"david"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                type: 'Layout::Condition',
              },
              {
                id: 9,
                parent_id: 8,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'random_attribue_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
              {
                id: 10,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'company',
                editor: 'radio',
                normalized_input_prefix: 'contact@0',
                type: 'Association::BelongsTo',
                value_position: 'right',
                inline: true,
                possible_values: [
                  {
                    value_record: {
                      id: '018c682e-492c-70f2-bac2-90c2b64ad291',
                      type: 'Record',
                      name: 'Toto',
                    },
                    translations: [{
                      text: 'A',
                      locale: 'fr',
                    }],
                    position: 0,
                  },
                  {
                    value_record: {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300e',
                      type: 'Record',
                      name: 'Titi',
                    },
                    translations: [{
                      text: 'B',
                      locale: 'fr',
                    }],
                    position: 1,
                  },
                ],
              },
              {
                id: 20,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                #company contain_id is 018c682e-492c-70f2-bac2-90c2b64ad291 && covility not_equal to 'mr'
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"company"=>{"contains_id"=>"018c682e-492c-70f2-bac2-90c2b64ad291"}}]}]},
                                                    {"or"=>[{"and"=>[{"civility"=>{"not_equal"=>"mr"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                type: 'Layout::Condition',
              },
              {
                id: 21,
                parent_id: 20,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'mr_company',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                first_name: 'david became',
                middle_name: 'youzou',
                civility: 'mrs'
              },
              'contact@0.company@0': {
                id: '018c682e-492c-70f2-bac2-90c2b64ad291'
              },
              'record@0.addresses@0': {
                id: '17ad7795e-9899-47a9-a38f-6c1ead61991b', name: '3379 Passage Joliot Curie'
              }
            },
          )
          dynamic_form.status_code = 200
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should render children elements if first_name contain david' do
        expect(page).to have_selector('input[type="text"][name="contact[first_name]"][value="david became"]')
        expect(page).to have_selector('input[name="contact[last_name]"]')
      end

      it 'should render children elements if middle_name equal to youzou' do
        expect(page).to have_selector('input[type="text"][name="contact[middle_name]"][value="youzou"]')
        expect(page).to have_selector('input[name="contact[nick_name]"]')
      end

      it 'should render children elements if cility equal to mrs && firs_name contain david' do
        expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mr"]')
        expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mrs"][checked]')
        expect(page).to have_selector('input[name="contact[random_attribue_name]"]')
      end

      it 'should render children elements if company is Toto' do
        expect(page).to have_selector('input[type="radio"][name="contact[company]"][value="f0e19422-c637-460b-aa49-b1819d9f300e"]')
        expect(page).to have_selector('input[type="radio"][name="contact[company]"][value="018c682e-492c-70f2-bac2-90c2b64ad291"][checked]')
        expect(page).to have_selector('input[name="contact[mr_company]"]')
      end

      it 'should render children elements if address contains 3379 Passage Joliot Curie' do
        ## TODO: has_many relation
        # {"addresses[]"=>{"contains_id"=>"018c682f-7e10-73bc-9f29-866ac00f65ee"}, "klass"=>"Contact", "path"=>"addresses"}
        ## TODO variable target
        # {"civility"=>{"equal"=>{"variable"=>"translatable_string"}}, "klass"=>"Contact", "path"=>"civility"}
        expect(page).to have_css('.ts-control div', text: "3379 Passage Joliot Curie")
      end
    end

    context 'condition not fulfilled' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Contact',
            elements: [
              {
                id: 1,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'first_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
              {
                id: 2,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"first_name"=>{"contains"=>"david"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                type: 'Layout::Condition',
              },
              {
                id: 3,
                parent_id: 2,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'last_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
              {
                id: 4,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'middle_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
              {
                id: 5,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"middle_name"=>{"equal"=>"youzou"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                type: 'Layout::Condition',
              },
              {
                id: 6,
                parent_id: 5,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'nick_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
              {
                id: 7,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'civility',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::Enum',
                editor: 'radio',
              },
              {
                id: 8,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                #civility equal Mr. and first_name contain david
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"civility"=>{"equal"=>"mrs"}}]}]},{"or"=>[{"and"=>[{"first_name"=>{"contains"=>"david"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                type: 'Layout::Condition',
              },
              {
                id: 9,
                parent_id: 8,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'random_attribue_name',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
              {
                id: 10,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'company',
                editor: 'radio',
                normalized_input_prefix: 'contact@0',
                type: 'Association::BelongsTo',
                value_position: 'right',
                inline: true,
                possible_values: [
                  {
                    value_record: {
                      id: '018c682e-492c-70f2-bac2-90c2b64ad291',
                      type: 'Record',
                      name: 'Toto',
                    },
                    translations: [{
                      text: 'A',
                      locale: 'fr',
                    }],
                    position: 0,
                  },
                  {
                    value_record: {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300e',
                      type: 'Record',
                      name: 'Titi',
                    },
                    translations: [{
                      text: 'B',
                      locale: 'fr',
                    }],
                    position: 1,
                  },
                ],
              },
              {
                id: 20,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                #company contain_id is 018c682e-492c-70f2-bac2-90c2b64ad291 && covility not_equal to 'mr'
                condition_formula: {"or"=>[{"and"=>[{"or"=>[{"and"=>[{"company"=>{"contains_id"=>"018c682e-492c-70f2-bac2-90c2b64ad291"}}]}]},
                                                    {"or"=>[{"and"=>[{"civility"=>{"not_equal"=>"mr"}}]}]}]}]},
                normalized_input_prefix: 'contact@0',
                type: 'Layout::Condition',
              },
              {
                id: 21,
                parent_id: 20,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'mr_company',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::String',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                first_name: 'jaona became',
                middle_name: 'coca cola', #middle_name
                civility: 'mr'
              },
            },
          )
          dynamic_form.status_code = 200
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should not render children elements if first_name value does not contain david' do
        expect(page).to have_selector('input[type="text"][name="contact[first_name]"][value="jaona became"]')
        expect(page).not_to have_selector('input[name="contact[last_name]"]')
      end

      it 'should not render children elements if middle_name value is not youzou' do
        expect(page).to have_selector('input[type="text"][name="contact[middle_name]"][value="coca cola"]')
        expect(page).not_to have_selector('input[name="contact[nick_name]"]')
      end

      it 'should not render children elements if cility equal to mr or firs_name does not contain david' do
        expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mr"][checked]')
        expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mrs"]')
        expect(page).not_to have_selector('input[name="contact[random_attribue_name]"]')
      end

      it 'should not render mr_company element if civility is mr or company id is not 018c682e-492c-70f2-bac2-90c2b64ad291' do
        expect(page).to have_selector('input[type="radio"][name="contact[company]"][value="f0e19422-c637-460b-aa49-b1819d9f300e"]')
        expect(page).to have_selector('input[type="radio"][name="contact[company]"][value="018c682e-492c-70f2-bac2-90c2b64ad291"]')
        expect(page).not_to have_selector('input[name="contact[mr_company]"]')
      end
    end

    context 'change an input' do
    end
  end

  describe 'rendering without condition_formula' do
    context 'condition not fulfilled' do

      it 'should not render children elements' do
        mount do
          Form(record: Record.new) do
            Form::Element::Layout::Condition(attr: 'toto') do
              Form::Element::Attribute::String(attribute_name: 'attr')
            end
          end
        end

        expect(
          has_css?('input[name="record[attr]"]')
        ).to eq false
      end

    end

    context 'condition fulfilled' do

      it 'should render children elements' do
        mount do
          Form(record: Record.new(attr: 'toto')) do
            Form::Element::Layout::Condition(attr: 'toto') do
              Form::Element::Attribute::String(attribute_name: 'attr')
            end
          end
        end

        expect(
          has_css?('input[name="record[attr]"]')
        ).to eq true
      end

    end

    context 'change an input' do

      context 'in order to make condition fulfilled' do

        it 'should render children elements' do
          mount do
            Form(record: Record.new(attr1: 'toto', cond: false)) do
              Form::Element::Attribute::Boolean(attribute_name: 'cond')
              Form::Element::Layout::Condition(cond: true) do
                Form::Element::Attribute::String(attribute_name: 'attr')
              end
            end
          end

          expect(
            has_css?('input[name="record[attr]"]')
          ).to eq false

          find('input[name="record[cond]"]').click

          expect(
            has_css?('input[name="record[attr]"]')
          ).to eq true
        end
      end

      context 'in order to make condition not fulfilled' do

        it 'should not render children elements' do
          mount do
            Form(record: Record.new(attr1: 'toto', cond: true)) do
              Form::Element::Attribute::Boolean(attribute_name: 'cond')
              Form::Element::Layout::Condition(cond: true) do
                Form::Element::Attribute::String(attribute_name: 'attr')
              end
            end
          end

          expect(
            has_css?('input[name="record[attr]"]')
          ).to eq true

          find('input[name="record[cond]"]').click

          expect(
            has_css?('input[name="record[attr]"]')
          ).to eq false
        end
      end

      describe 'clean params of conditions' do

        context 'with params automatically determined' do

          it 'should be done' do
            mount do
              Form(record: Record.new(attr1: 'toto')) do
                Form::Element::Attribute::Boolean(attribute_name: 'cond')
                Form::Element::Layout::Condition(cond: false) do
                  Form::Element::Attribute::String(attribute_name: 'attr1')
                end
                Form::Element::Layout::Condition(cond: true) do
                  Form::Element::Attribute::String(attribute_name: 'attr2')
                end
              end
            end

            find('input[name="record[attr1]"]').set('A')

            expect(
              page_eval do
                Form.current.submission.params.dig('record', 'attr1').to_n
              end
            ).to be_present

            find('input[name="record[cond]"]').click

            find('input[name="record[attr2]"]').set('B')

            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'record' => {
                  'cond' => '1',
                  'attr2' => 'B'
                }
              }
            )
          end

        end

        context 'with params provided' do

          it 'should be done' do
            mount do
              Form(record: Record.new(attr1: 'toto')) do
                Form::Element::Attribute::Boolean(attribute_name: 'cond')
                Form::Element::Layout::Condition(cond: false, to_clean: ['attr1']) do
                  Form::Element::Attribute::String(attribute_name: 'attr1')
                end
                Form::Element::Layout::Condition(cond: true, to_clean: ['attr2']) do
                  Form::Element::Attribute::String(attribute_name: 'attr2')
                end
              end
            end

            find('input[name="record[attr1]"]').set('A')

            expect(
              page_eval do
                Form.current.submission.params.dig('record', 'attr1').to_n
              end
            ).to be_present

            find('input[name="record[cond]"]').set(true)

            find('input[name="record[attr2]"]').set('B')

            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'record' => {
                  'cond' => '1',
                  'attr2' => 'B'
                }
              }
            )
          end

          it 'should not clean used values' do
            mount do
              $record = Record.new(attr1: 'toto')
              Form(record: $record) do
                Form::Element::Layout::Condition(cond: true, to_clean: ['attr1']) do
                  Form::Element::Attribute::String(attribute_name: 'attr1')
                end
              end
            end

            page_exec do
              $record.attributes['cond'] = '1' # simulate record changed later TODO should be = true ?
              Form.current.mutate
            end

            expect(page).to have_css('[name="record[attr1]"][value="toto"]')
          end

        end



      end

    end

    context 'nested' do
      before(:each) do
        page_exec do
          class NestedNested < HyperResource::Base
          end
          class Nested < HyperResource::Base
            has_many :nested_nesteds, class_name: 'NestedNested'
          end
          class Record < HyperResource::Base
            has_many :nesteds, class_name: 'Nested'
          end
        end
      end

      context 'condition inside association' do

        it 'should render children elements with correct input name' do
          mount do
            Form(record: Record.new(nesteds: [Nested.new(attr: 'toto')])) do
              Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                Form::Element::Layout::Condition(attr: 'toto') do
                  Form::Element::Attribute::String(attribute_name: 'attr')
                end
              end
            end
          end

          expect(
            has_css?('input[name="record[nesteds_attributes][0][attr]"]')
          ).to eq true
        end

      end

      context 'condition outside association' do

        it 'should render children elements with correct input name' do
          mount do
            Form(record: Record.new(nesteds: [Nested.new(nested_nesteds: NestedNested.new(attr: 'toto'))])) do
              Form::Element::Attribute::Boolean(attribute_name: 'cond')
              #Form::Element::Layout::Condition(cond: false) do
              #end
              #Form::Element::Layout::Condition(cond: true) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                  Form::Element::Association::HasMany(attribute_name: 'nested_nesteds', mode: 'nested_form') do
                    Form::Element::Attribute::String(attribute_name: 'attr')
                  end
                end
              #end
            end
          end

          #expect(
            #has_css?('input[name="record[nesteds_attributes][0][nested_nesteds_attributes][0][attr]"]')
          #).to eq false

          #find('input[name="record[cond]"]').click

          expect(
            has_css?('input[name="record[nesteds_attributes][0][nested_nesteds_attributes][0][attr]"]')
          ).to eq true

        end

      end
    end
  end
end
