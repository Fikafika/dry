describe 'Form::Element::Control::ItemHeader', type: :system do
  before(:each) do
    page_exec do
      class Nested < HyperResource::Base
      end
      class Record < HyperResource::Base
        has_many :nesteds, class_name: 'Nested'
      end
    end
  end

  describe 'delete button' do

    context '' do
      before(:each) do
        mount do
          record = Record.new(
            nesteds: [Nested.new(attr: 'A'), Nested.new(attr: 'B')]
          )

          Form(record: record) do
            Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
              Form::Element::Attribute::String(attribute_name: 'attr')
            end
            Form::Element::Control::AddButton(attribute_name: 'nesteds')
          end
        end
      end

      it 'should display several delete buttons' do
        expect(page).to have_css('.btn[href="#delete"]', count: 2)
      end

      it 'should remove when click on button' do
        expect(page).to have_css('input', count: 2)
        all('.btn[href="#delete"]').first.click
        find('.btn', text: 'Oui').click
        expect(page).to have_css('input', count: 1)
      end

      it 'should keep add button' do
        all('.btn[href="#delete"]').last.click
        find('.btn', text: 'Oui').click
        expect(page).to have_css('.btn[href="#add"]', count: 1)
      end

    end

    context 'min' do

      it 'should not display a delete button when items count is equal to min' do # a disabled delete button could also be acceptable
        mount do
          record = Record.new(
            nesteds: [Nested.new(attr: 'A'), Nested.new(attr: 'B')]
          )

          Form(record: record) do
            Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form', min: record.nesteds.length) do
              Form::Element::Attribute::String(attribute_name: 'attr')
            end
            Form::Element::Control::AddButton(attribute_name: 'nesteds')
          end
        end
        expect(all('.btn[href="#delete"]').length).to eq 0
      end

      it 'should display delete button after click on add button' do
        mount do
          record = Record.new(
            nesteds: [Nested.new(attr: 'A'), Nested.new(attr: 'B')]
          )

          Form(record: record) do
            Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form', min: record.nesteds.length) do
              Form::Element::Attribute::String(attribute_name: 'attr')
            end
            Form::Element::Control::AddButton(attribute_name: 'nesteds')
          end
        end
        expect(all('.btn[href="#delete"]').length).to eq 0
        find('.btn[href="#add"]').click

        expect(all('.btn[href="#delete"]').length).to eq 3 # record.nesteds.length + 1
      end

    end

  end

  describe 'up/down buttons' do
    before(:each) do
      page_exec do
        class OrderableNested < HyperResource::Base
          attribute :position, type: Integer
        end
        class Record < HyperResource::Base
          has_many :orderable_nesteds, class_name: 'OrderableNested'
        end
      end
    end

    it 'should not be displayed if not orderable' do
      mount do
        record = Record.new(
          nesteds: [Nested.new(attr: 'A'), Nested.new(attr: 'B'), Nested.new(attr: 'C')]
        )
        Form(record: record) do
          Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
            Form::Element::Attribute::String(attribute_name: 'attr')
          end
        end
      end
      expect(page).to_not have_css('.btn[href="#up"]')
    end

    context 'orderable' do
      context '' do
        before(:each) do
          mount do
            record = Record.new(
              orderable_nesteds: [
                OrderableNested.new(attr: 'A', position: 0),
                OrderableNested.new(attr: 'B', position: 1),
                OrderableNested.new(attr: 'C', position: 2, _destroy: true),
                OrderableNested.new(attr: 'D', position: 3),
                OrderableNested.new(attr: 'E', position: 4),
              ]
            )
            Form(record: record) do
              Form::Element::Association::HasMany(attribute_name: 'orderable_nesteds', mode: 'nested_form') do
                Form::Element::Attribute::String(attribute_name: 'attr')
              end
            end
          end
        end

        it 'should display several up/down buttons' do
          expect(page).to have_css('.btn[href="#up"]', count: 4)
        end

        it 'should up if not first' do
          all('.btn[href="#up"]')[3].click
          expect(find('input[name="record[orderable_nesteds_attributes][0][attr]"]').value).to eq('A')
          expect(find('input[name="record[orderable_nesteds_attributes][1][attr]"]').value).to eq('B')
          expect(page).not_to have_selector('input[name="record[orderable_nesteds_attributes][2][attr]"]')
          expect(find('input[name="record[orderable_nesteds_attributes][3][attr]"]').value).to eq('E')
          expect(find('input[name="record[orderable_nesteds_attributes][4][attr]"]').value).to eq('D')
        end

        it 'should not up if first' do
          expect(all('.btn[href="#up"]')[0][:class]).to include('disabled')
        end

        it 'should down if not last' do
          all('.btn[href="#down"]')[0].click
          expect(find('input[name="record[orderable_nesteds_attributes][0][attr]"]').value).to eq('B')
          expect(find('input[name="record[orderable_nesteds_attributes][1][attr]"]').value).to eq('A')
          expect(page).not_to have_selector('input[name="record[orderable_nesteds_attributes][2][attr]"]')
          expect(find('input[name="record[orderable_nesteds_attributes][3][attr]"]').value).to eq('D')
          expect(find('input[name="record[orderable_nesteds_attributes][4][attr]"]').value).to eq('E')
        end

        it 'should not down if last' do
          expect(all('.btn[href="#down"]')[3][:class]).to include('disabled')
        end

        it 'should skip destroyed element when up' do
          all('.btn[href="#up"]')[2].click
          expect(find('input[name="record[orderable_nesteds_attributes][0][attr]"]').value).to eq('A')
          expect(find('input[name="record[orderable_nesteds_attributes][1][attr]"]').value).to eq('D')
          expect(page).not_to have_selector('input[name="record[orderable_nesteds_attributes][2][attr]"]')
          expect(find('input[name="record[orderable_nesteds_attributes][3][attr]"]').value).to eq('B')
          expect(find('input[name="record[orderable_nesteds_attributes][4][attr]"]').value).to eq('E')
        end

        it 'should skip destroyed element when down' do
          all('.btn[href="#down"]')[1].click
          expect(find('input[name="record[orderable_nesteds_attributes][0][attr]"]').value).to eq('A')
          expect(find('input[name="record[orderable_nesteds_attributes][1][attr]"]').value).to eq('D')
          expect(page).not_to have_selector('input[name="record[orderable_nesteds_attributes][2][attr]"]')
          expect(find('input[name="record[orderable_nesteds_attributes][3][attr]"]').value).to eq('B')
          expect(find('input[name="record[orderable_nesteds_attributes][4][attr]"]').value).to eq('E')
        end

      end

      context 'empty' do
        before(:each) do
          mount do
            record = Record.new(
              orderable_nesteds: []
            )
            Form(record: record) do
              Form::Element::Association::HasMany(attribute_name: 'orderable_nesteds', mode: 'nested_form') do
                Form::Element::Attribute::String(attribute_name: 'attr')
              end
              Form::Element::Control::AddButton(attribute_name: 'orderable_nesteds')
            end
          end
        end

        describe 'add' do
          it 'should set position' do
            find('.btn[href="#add"]').click
            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'record' => {
                  'orderable_nesteds_attributes' => [
                    {
                      'attr' => nil,
                      'position' => 0,
                    },
                  ]
                }
              }
            )
            find('.btn[href="#add"]').click
            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'record' => {
                  'orderable_nesteds_attributes' => [
                    {
                      'attr' => nil,
                      'position' => 0,
                    },
                    {
                      'attr' => nil,
                      'position' => 1,
                    },
                  ]
                }
              }
            )
          end
        end
      end

    end

  end

end
