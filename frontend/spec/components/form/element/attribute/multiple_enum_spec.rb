describe 'Form::Element::Attribute::MultipleEnum', type: :system do
  before(:each) do
    page_exec do
      class Record < HyperResource::Base
        def self.actions
          ['C', 'R', 'U', 'D']
        end
      end
    end
  end

  context 'record' do
    context 'editor = checkbox' do
      before(:each) do
        mount do
          Form(record: Record.new(actions: ['C', 'R'])) do
            Form::Element::Attribute::MultipleEnum(attribute_name: 'actions', editor: 'checkbox')
          end
        end
      end

      it 'should display checkboxes' do
        expect(page).to have_css('input[type=checkbox][name="record[actions][]"][value="C"]')
        expect(page).to have_css('input[type=checkbox][name="record[actions][]"][value="R"]')
        expect(page).to have_css('input[type=checkbox][name="record[actions][]"][value="U"]')
        expect(page).to have_css('input[type=checkbox][name="record[actions][]"][value="D"]')

        expect(find('input[type=checkbox][name="record[actions][]"][value="C"]')).to be_checked
        expect(find('input[type=checkbox][name="record[actions][]"][value="R"]')).to be_checked
        expect(find('input[type=checkbox][name="record[actions][]"][value="U"]')).to_not be_checked
        expect(find('input[type=checkbox][name="record[actions][]"][value="D"]')).to_not be_checked

        expect(page_eval{ Form.current.submission.params.to_n }).to eq({'record' => {'actions' => ['C', 'R']}})
      end

      it 'should change value when check' do
        find('input[type=checkbox][name="record[actions][]"][value="U"]').click
        expect(find('input[type=checkbox][name="record[actions][]"][value="C"]')).to be_checked
        expect(find('input[type=checkbox][name="record[actions][]"][value="R"]')).to be_checked
        expect(find('input[type=checkbox][name="record[actions][]"][value="U"]')).to be_checked
        expect(find('input[type=checkbox][name="record[actions][]"][value="D"]')).to_not be_checked

        expect(page_eval{ Form.current.submission.params.to_n }).to eq({'record' => {'actions' => ['C', 'R', 'U']}})
      end

      it 'should change value when uncheck' do
        find('input[type=checkbox][name="record[actions][]"][value="R"]').click
        expect(find('input[type=checkbox][name="record[actions][]"][value="C"]')).to be_checked
        expect(find('input[type=checkbox][name="record[actions][]"][value="R"]')).to_not be_checked
        expect(find('input[type=checkbox][name="record[actions][]"][value="U"]')).to_not be_checked
        expect(find('input[type=checkbox][name="record[actions][]"][value="D"]')).to_not be_checked

        expect(page_eval{ Form.current.submission.params.to_n }).to eq({'record' => {'actions' => ['C']}})
      end

    end

    context 'editor = select2' do
      before(:each) do
        mount do
          Form(record: Record.new(actions: ['C', 'R'])) do
            Form::Element::Attribute::MultipleEnum(attribute_name: 'actions', editor: 'select2')
          end
        end
      end

      it 'should display items' do
        expect(page).to have_css('.ts-control .item', text: 'C')
        expect(page).to have_css('.ts-control .item', text: 'R')
      end

      it 'should change value when autocomplete' do
        find('.ts-wrapper').click
        expect(page).to have_css('.ts-dropdown .option', text: 'U')
        expect(page).to have_css('.ts-dropdown .option', text: 'D')
        find('.ts-dropdown .option', text: 'U').click

        expect(page_eval{ Form.current.submission.params.to_n }).to eq({'record' => {'actions' => ['C', 'R', 'U']}})
      end

      it 'should change value when remove item' do
        find('.ts-wrapper .item', text: 'R').find('.remove').click
        expect(page_eval{ Form.current.submission.params.to_n }).to eq({'record' => {'actions' => ['C']}})
      end

    end

  end

end
