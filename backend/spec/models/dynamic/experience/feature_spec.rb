describe Dynamic::Experience::Feature do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Experience::Feature')
  end

  context 'when enabled' do
    before(:each) do
      @account = @schema.klasses.create!(name: 'Account')
      @contact = @schema.klasses.create!(name: 'Contact')
    end

    describe 'Experience concern' do

      it 'should raise when owner and organization klasses are missing' do
        expect{@feature.update!(enabled: true)}.to raise_error{ActiveRecord::RecordInvalid}
      end

      context 'owner and organization klasses filled' do
        before(:each) do
          @feature.options.detect {|o| o.name == 'owner_klass'}.update!(value: @contact)
          @feature.options.detect {|o| o.name == 'organization_klass'}.update!(value: @account)
          @experience_concern = @feature.concerns.detect {|c| c.name == 'Experience'}
        end

        it 'should create experience attributes' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            Dynamic::Schema::Attribute::Base.where(klass: @experience_concern.reload.klass).count
          }.from(0).to(9)
        end

        it 'should update name_attribute' do
          @feature.update!(enabled: true)
          @experience_concern.reload
          title_attribute = @experience_concern.options.detect {|o| o.name == 'title_attribute'}.value
          expect(@experience_concern.klass.name_attribute_id).to eq(title_attribute.id)
        end
      end
    end

    describe 'Job concern' do

      context 'klass options filled' do
        before(:each) do
          @feature.options.detect {|o| o.name == 'owner_klass'}.update!(value: @contact)
          @feature.options.detect {|o| o.name == 'organization_klass'}.update!(value: @account)
          @feature.update!(enabled: true)
        end

        it 'should create an attribute for Contact klass' do
          expect(@contact.reload.attrs.last).to eq(Dynamic::Schema::Attribute::String.find_by(name: 'function'))
        end

        it 'should create an association between Contact and JobExperience' do
          professional_experiences_target_klass = @contact.associations.detect {|a| a.name == 'professional_experiences'}.target_klass
          expect(professional_experiences_target_klass).to eq(Dynamic::Schema::Klass.find_by(name: 'JobExperience'))
        end

        it 'should create an association for Account and Contact klass' do
          members_target_klass = @account.associations.detect {|a| a.name == 'collaborators'}.target_klass
          expect(members_target_klass).to eq(Dynamic::Schema::Klass.find_by(name: 'JobExperience'))
        end

        it 'should update ExperienceJob input forms witht pages' do
          form = Dynamic::Form.where(klass_name: 'D::My::JobExperience', actions: 1).first
          page_elements = form.elements.select {|e| e.type == 'Layout::Page'}
          expect(page_elements.count).to eq(2)

          first_page = page_elements.detect {|e| e.position == 0}
          last_page = page_elements.detect {|e| e.position == 1}
          expect(form.elements.count {|e| e.parent == first_page}).to eq(form.elements.count - 3)
          expect(form.elements.count {|e| e.parent == last_page}).to eq(1)
        end
      end
    end
  end
end
