describe Dynamic::Event::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @klass = @schema.klasses.create!(
      name: 'Interview',
      attrs_attributes: [
        {
          name: 'label',
          type: 'String',
        },
        {
          name: 'debut',
          type: 'DateTime',
        },
        {
          name: 'fin',
          type: 'DateTime',
        },
        {
          name: 'annulation',
          type: 'DateTime',
        },
      ]
    )
    @label_attr = @klass.attrs.detect {|a| a.name == 'label'}
    @start_attr = @klass.attrs.detect {|a| a.name == 'debut'}
    @end_attr = @klass.attrs.detect {|a| a.name == 'fin'}
    @cancel_attr = @klass.attrs.detect {|a| a.name == 'annulation'}

    @feature = @schema.features.find_by(name: 'Dynamic::Event::Feature')
    @dup_event_options = @feature.concern_templates.detect {|t| t.name == 'Event'}.options.map do |o|
      h = o.as_json.slice("name", "human_name_fr", "human_name_en", "value")
      h['type'] = o.type
      h['coder_type'] = o.coder_type
      h
    end
  end

  describe '.after_enabled' do

    context 'Event concern' do

      context 'with klass missing from concern' do
        before(:each) do
          @feature.concerns.create!(
            name: 'Event',
            options_attributes: @dup_event_options
          )
        end

        it 'should raise an error' do
          expect{@feature.update!(enabled: true)}.to raise_error{ActiveRecord::RecordInvalid}
        end

      end

      context 'witout mapping date attributes' do
        before(:each) do
          @feature.concerns.create!(
            name: 'Event',
            klass: @klass,
            options_attributes: @dup_event_options
          )
        end

        it 'should create attributes' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            @klass.attrs.count
          }.by(3)
        end

        it 'should create validations' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            @klass.validations.count
          }.by(4)
        end

      end

      context 'with date attributes mapped' do
        before(:each) do
          @dup_event_options.detect {|o| o['name'] == 'starting_date'}['value'] = @start_attr.id
          @dup_event_options.detect {|o| o['name'] == 'ending_date'}['value'] = @end_attr.id
          @dup_event_options.detect {|o| o['name'] == 'cancelation_date'}['value'] = @cancel_attr.id
          @concern = @feature.concerns.create!(
            name: 'Event',
            klass: @klass,
            options_attributes: @dup_event_options
          )
        end

        it 'should not create new attributes' do
          expect{
            @feature.update!(enabled: true)
          }.to_not change{
            Dynamic::Schema::Attribute::Base.count
          }
        end

        context 'wrong attribute type' do
          before(:each) do
            @concern.options.first.update!(value: @label_attr.id)
          end

          it 'should raise an error' do
            expect{@feature.update!(enabled: true)}.to raise_error{ActiveRecord::RecordInvalid}
          end
        end

      end

      context 'with Indisponibility concern' do
        before(:each) do
          @feature.concerns.create!(
            name: 'Event',
            klass: @klass,
            options_attributes: @dup_event_options
          )
          @klass_2 = @schema.klasses.create!(name: 'Address')
          @indisponibility_attribute_options = [
            {
              name: 'indisponibility_assoc',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: ''
            },
            {
              name: 'event_klass',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klass',
              value: @klass.id
            },
          ]
        end

        context 'without specifying an association' do
          before(:each) do
            @feature.concerns.create!(
              name: 'Indisponibility',
              klass: @klass_2,
              options_attributes: @indisponibility_attribute_options,
            )
          end

          it 'should create one when indisponibility_assoc is empty' do
            expect{
              @feature.update!(enabled: true)
            }.to change{
              @klass_2.associations.count
            }.by(1)
          end
        end

        context 'with association specified' do
          before(:each) do
            @assoc = @klass_2.associations.create!(
              name: 'vacancies',
              target_klass: @klass,
              type: 'HasMany'
            )
            @indisponibility_attribute_options[0][:value] = @assoc
            @feature.concerns.create!(
              name: 'Indisponibility',
              klass: @klass_2,
              options_attributes: @indisponibility_attribute_options,
            )
          end

          it 'should create one when indisponibility_assoc is empty' do
            expect{
              @feature.update!(enabled: true)
            }.to_not change{
              @klass_2.associations.count
            }
          end
        end

      end

    end

  end

end
