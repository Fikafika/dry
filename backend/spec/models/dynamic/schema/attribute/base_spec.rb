describe Dynamic::Schema::Attribute::Base, elasticsearch: false, sidekiq: false do

  describe 'default forms' do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
      @klass = @schema.klasses.create(name: 'Klass')
      @default_form_count = 4
    end

    describe '.create' do
      it 'should create an element in default forms' do
        expect{
          @klass.attrs.create!(name: 'Attr', type: 'String')
        }.to change{
          Dynamic::Form::Element::Base.count
        }.by(@default_form_count)
      end

      context 'create attribute' do
        describe '.check compact' do
          it 'should have value compact in function purpose form' do
            @attr = @klass.attrs.create!(name: 'Klass', type: 'String')
            form1 = @schema.forms.where(klass_name: @klass.const_absolute_name, purpose: 'thumbnail').first
            element1 = form1.elements.find_by!(attribute_name: 'klass')
            form2 = @schema.forms.where(klass_name: @klass.const_absolute_name, purpose: 'sheet').first
            element2 = form2.elements.find_by!(attribute_name: 'klass')

            expect(element1.compact).to be(true)
            expect(element2.compact).to be(false)
          end
        end
      end
    end

    describe '.destroy' do
      before(:each) do
        @attr = @klass.attrs.create!(name: 'Klass', type: 'String')
      end
      it 'should destroy corresponding elements in default forms' do
        expect{
          @attr.destroy
        }.to change{
          Dynamic::Form::Element::Base.count
        }.by(-@default_form_count)
      end
    end


    describe '.update' do
      before(:each) do
        @attr = @klass.attrs.create!(name: 'Attr', type: 'String')
      end

      context 'human_name changed' do
        xit "should rename element's label" do
          expect{
            @attr.update(human_name_en: "New name")
          }.to change{
            Dynamic::Form::Element::Base.last.label_en
          }.to('New name')
        end
      end

      context 'name changed' do
        it 'should change autocomplete filters columns' do
          @klass.associations.create(name: 'associated', target_klass: @klass, type: 'BelongsTo')
          form = @schema.forms.where(klass_name: @klass.const_absolute_name).first
          element = form.elements.detect{|e| e.class.name.end_with?('BelongsTo')}
          element.update(autocomplete_filters: {attr: 'A'})

          expect{
            @attr.update(name: 'attr2')
          }.to change {
            element.class.find(element.id).autocomplete_filters
          }.from({'attr' => 'A'}).to({'attr2' => 'A'})
        end

        xit 'should change autocomplete filters variables' # TODO
      end

    end


  end

  describe 'formula and elasticsearch', elasticsearch: true, sidekiq: true do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
      @klass = @schema.klasses.create(name: 'Klass', attrs_attributes: [{name: 'attr', type: 'String'}])
      @schema.load

      $formula_jobs = []; $elasticsearch_jobs = []; $model_dependency_jobs = []

      allow(::Dynamic::Formula::Worker).to receive(:perform_async).and_wrap_original do |m, *args|
        $formula_jobs << args; m.call(*args)
      end

      allow(::ModelDependency::Worker).to receive(:perform_async).and_wrap_original do |m, *args|
        $elasticsearch_jobs << args; m.call(*args)
      end

      allow(::Dynamic::Elasticsearch::Worker).to receive(:perform_async).and_wrap_original do |m, *args|
        $model_dependency_jobs << args; m.call(*args)
      end

      # existing record:
      ::ModelDependency::Worker.wait_for_complete do
        @record = D::My::Klass.create!(attr: 'A')
      end
      expect(@record.__opensearch__.source['attr']).to eq 'A'

      $formula_jobs = []; $elasticsearch_jobs = []; $model_dependency_jobs = []
    end

    describe 'create' do

      context 'with formula' do
        before(:each) do
          ::Dynamic::Formula::Worker.wait_for_complete do
            @attr = @klass.attrs.create!(name: 'computed_attr', type: 'String', formula: '"B"')
          end
          @schema.load
          @record = D::My::Klass.find(@record.id)
        end

        it 'should compute all and reindex all records' do
          expect(@record.computed_attr).to eq 'B'
          expect(@record.__opensearch__.source['computed_attr']).to eq 'B'

          expect($formula_jobs.length).to eq 1
          expect($model_dependency_jobs.length).to eq 1 # why not a single job that combine formula and elasticsearch job for this class and model_dependency for dependencies
          expect($elasticsearch_jobs.length).to eq 0
        end

      end

      context 'without formula' do
        before(:each) do
          ::Dynamic::Formula::Worker.wait_for_complete do
            @attr = @klass.attrs.create!(name: 'computed_attr', type: 'String', formula: '')
          end
          @schema.load
          @record = D::My::Klass.find(@record.id)
        end

        it 'should not compute all and it should reindex all' do
          expect(@record.__opensearch__.source.has_key?('computed_attr')).to be_truthy
          expect(@record.__opensearch__.source['computed_attr']).to be_nil
          expect($formula_jobs.length).to eq 0
          expect($model_dependency_jobs.length).to eq 1
          expect($elasticsearch_jobs.length).to eq 0
        end
      end

    end

    describe 'update' do
      before(:each) do
        ::Dynamic::Formula::Worker.wait_for_complete do
          @attr = @klass.attrs.create!(name: 'computed_attr', type: 'String', formula: '"B"')
        end
        $formula_jobs = []; $elasticsearch_jobs = []; $model_dependency_jobs = []
      end

      context 'with formula changed' do
        before(:each) do
          ::Dynamic::Formula::Worker.wait_for_complete do
            @attr.update(formula: '"C"')
          end
          @schema.load
          @record = D::My::Klass.find(@record.id)
        end

        it 'should compute all and reindex changes' do
          expect(@record.computed_attr).to eq 'C'
          expect(@record.__opensearch__.source['computed_attr']).to eq 'C'

          expect($formula_jobs.length).to eq 1
          expect($model_dependency_jobs.length).to eq 0 # 0 because formula trigger model_dependency if computed value changed
          expect($elasticsearch_jobs.length).to eq 0
        end
      end

      context 'without formula changed' do
        before(:each) do
          ::Dynamic::Formula::Worker.wait_for_complete do
            @attr.update(formula: '"B"')
          end
          @schema.load
          @record = D::My::Klass.find(@record.id)
        end

        it 'should do nothing' do
          expect(@record.computed_attr).to eq 'B'
          expect(@record.__opensearch__.source['computed_attr']).to eq 'B'
          expect($formula_jobs).to be_empty
          expect($model_dependency_jobs).to be_empty
          expect($elasticsearch_jobs).to be_empty
        end
      end

    end

  end

end

