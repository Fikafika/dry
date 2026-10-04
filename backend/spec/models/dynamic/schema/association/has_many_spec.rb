describe Dynamic::Schema::Association::HasMany, elasticsearch: false, sidekiq: false do

  describe :AssociationCreateDefaultForms do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
      @klass = @schema.klasses.create!(name: 'Klass')
      @associated_klass = @schema.klasses.create!(name: 'AssociatedKlass')
    end

    describe '.create' do
      it 'should create default forms' do
        expect {
          @klass.associations.create!(name: 'associateds', target_klass: @associated_klass, type: 'HasMany')
        }.to change{
          @schema.forms.count
        }.by([[:new]].length)
      end

      context 'inverse_of belongs_to' do
        before(:each) do
          @inverse = @associated_klass.associations.create!(name: 'owner', type: 'BelongsTo')
          @assoc = @klass.associations.create!(
            name: 'associateds',
            target_klass: @associated_klass,
            inverse_of: @inverse,
            type: 'HasMany',
          )
          @created_form = @schema.forms.last
        end

        it 'should not add element for this inverse' do
          expect(
            @created_form.elements.map(&:attribute_name)
          ).to_not include('owner')
        end
      end
    end

    describe '.destroy' do
      before(:each) do
        @association = @klass.associations.create!(name: 'associateds', target_klass: @associated_klass, type: 'HasMany')
      end

      it 'should destroy default forms' do
        expect {
          @association.destroy
        }.to change {
          @schema.forms.count
        }.by(-[[:new]].length)
      end
    end

  end

  describe :AssociationUpdateDefaultLayouts do
    describe '.create' do
      before(:each) do
        @schema = Dynamic::Schema.create!(name: 'my')
        @klass = @schema.klasses.create!(name: 'Klass')
        @associated_klass = @schema.klasses.create!(name: 'AssociatedKlass')

        @edit_layout = @schema.layouts.with_action(:edit).where(klass_name: @klass.const_absolute_name).first
        @tab_bar = @edit_layout.elements.detect{|e| e.component == 'Crm::Sheet::TabBar' }
        @tab_all = @tab_bar.children.detect{|e| e.component_params['name'] == 'all'}

        @previous_association = @klass.associations.create!(name: 'previous_association', target_klass: @klass, type: 'HasMany') # create a first association in order to create a @scroller_tab_all
      end

      it "should update sheet's tab all" do
        expect{
          @association = @klass.associations.create!(name: 'associateds', target_klass: @associated_klass, type: 'HasMany')
        }.to change{
          @scroller_tab_all = @tab_all.descendants.detect{|e| e.component == 'InfiniteScroller' }
          @scroller_tab_all.component_params_converter_options['schema_association_ids'].length
        }.by(1)
        expect(@scroller_tab_all.component_params_converter_options['schema_association_ids']).to eq [@previous_association.id, @association.id]
      end

      it "should add a tab to sheet's tabbar" do
        expect{
          @association = @klass.associations.create!(name: 'associateds', target_klass: @associated_klass, type: 'HasMany')
        }.to change{
          @tab_bar.children.reload.length
        }.by(1)
        @last_tab_scroller = @tab_bar.children.last.descendants.detect{|e| e.component == 'InfiniteScroller' }
        expect(@last_tab_scroller.component_params_converter_options['schema_association_ids']).to eq [@association.id]
      end
    end

    describe '.update' do
      before(:each) do
        @schema = Dynamic::Schema.create!(name: 'my')
        @klass = @schema.klasses.create!(name: 'Klass')
        @associated_klass = @schema.klasses.create!(name: 'AssociatedKlass', icon: 'square')
        @associated_klass2 = @schema.klasses.create!(name: 'AssociatedKlass2', icon: 'circle')

        @edit_layout = @schema.layouts.with_action(:edit).where(klass_name: @klass.const_absolute_name).first
        @tab_bar = @edit_layout.elements.detect{|e| e.component == 'Crm::Sheet::TabBar' }
        @association = @klass.associations.create!(name: 'association1', target_klass: @associated_klass, type: 'HasMany')
        @tab = @tab_bar.children.detect{|e| e.component_params['name'] == 'association1'}
      end

      it "name should update tab name" do
        expect {
          @association.update(name: 'association2')
        }.to change {
          @tab.reload.component_params['name']
        }.to('association2')
      end

      it 'human_name should update tab translations' do
        expect {
          @association.update(human_name_fr: 'Assoc2')
        }.to change {
          @tab.reload.component_params.dig('translations', 'fr', 'title')
        }.to('Assoc2')
      end

      it "target_klass, should update tab icon" do
        expect {
          @association.update(target_klass: @associated_klass2)
        }.to change {
          @tab.reload.component_params['icon']
        }.from('square').to('circle')
      end
    end

    describe 'create through schema' do

      it "should add a tab to sheet's tabbar" do
        expect {
          Dynamic::Schema.create!(
            id: '01837e4e-979f-7387-ab9f-674260f628aa',
            name: 'my',
            klasses_attributes: [
              {
                id: '01837e4e-9bfe-7087-8e8c-80c627792037',
                name: 'Klass',
                associations_attributes: [
                  {
                    id: '01837e4e-9dec-72d5-ab6f-495ca29494c4',
                    name: 'associateds',
                    target_klass_id: '01837e4e-9cfd-7090-b259-7345bcc592f5',
                    type: 'HasMany',
                  }
                ]
              },
              {
                id: '01837e4e-9cfd-7090-b259-7345bcc592f5',
                name: 'AssociatedKlass',
              }
            ]
          )
        }.to change {
          schema = Dynamic::Schema.find_by_id('01837e4e-979f-7387-ab9f-674260f628aa')
          tab_count = if schema
            edit_layout = schema.layouts.with_action(:edit).where(klass_name: 'D::My::Klass').first
            tab_bar = edit_layout.elements.detect{|e| e.component == 'Crm::Sheet::TabBar' }
            tab_bar.children.length
          else
            0
          end
          tab_count
        }.by(2)
      end

    end


    describe '.destroy' do
      before(:each) do
        @schema = Dynamic::Schema.create!(name: 'my')
        @klass = @schema.klasses.create!(name: 'Klass')
        @associated_klass = @schema.klasses.create!(name: 'AssociatedKlass')

        @edit_layout = @schema.layouts.with_action(:edit).where(klass_name: @klass.const_absolute_name).first
        @tab_bar = @edit_layout.elements.detect{|e| e.component == 'Crm::Sheet::TabBar' }
        @tab_all = @tab_bar.children.detect{|e| e.component_params['name'] == 'all'}

        @previous_association = @klass.associations.create!(name: 'previous_association', target_klass: @klass, type: 'HasMany') # create a first association in order to create a @scroller_tab_all
        @association = @klass.associations.create!(name: 'associateds', target_klass: @associated_klass, type: 'HasMany')
      end

      it "should update sheet's tab all" do
        expect{
          @association.destroy
        }.to change{
          @scroller_tab_all = @tab_all.descendants.detect{|e| e.component == 'InfiniteScroller' }
          @scroller_tab_all.component_params_converter_options['schema_association_ids'].length
        }.by(-1)
        expect(@scroller_tab_all.component_params_converter_options['schema_association_ids']).to eq [@previous_association.id]
      end

      it "should remove a tab from sheet's tabbar" do
        expect{
          @association.destroy
        }.to change{
          @tab_bar.children.reload.length
        }.by(-1)
      end
    end

  end

end

