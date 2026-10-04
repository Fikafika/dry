describe Dynamic::Record::Base do

  describe '.diffential_update' do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
      @Tag = @schema.klasses.create!(name: 'Tag', attrs_attributes: [{name: 'name', type: 'String'}])
      @Document = @schema.klasses.create!(
        name: 'Document',
        attrs_attributes: [{name: 'name', type: 'String'}],
        associations_attributes: [
          {name: 'tags', type: 'HasMany', target_klass_id: @Tag.id}
        ],
      )
      @schema.load
    end

    it 'add and remove records of an association an a filtered list of records' do
      @tag1 = D::My::Tag.create!(name: 'tag1')
      @tag2 = D::My::Tag.create!(name: 'tag2')
      @tag3 = D::My::Tag.create!(name: 'tag3')

      Dynamic::Elasticsearch.wait_for_complete(timeout: 20) do
        @a1 = D::My::Document.create!(name: 'A 1', tags: [@tag1, @tag2])
        @a2 = D::My::Document.create!(name: 'A 2', tags: [@tag1, @tag3])
        @b = D::My::Document.create!(name: 'B')
      end

      expect{
        D::My::Document.where_filters(
          {name: {contains: 'A'}},
        ).differential_update(:all, {
          tags_associations_attributes: {
            _add: [{association_target_id: @tag3.id, association_target_type: 'D::My::Tag'}],
            _remove: [{association_target_id: @tag1.id, association_target_type: 'D::My::Tag'}],
          }
        })
      }.to change {
        @a1.tags.reload.map(&:name)
      }.to(['tag2', 'tag3']).and change {
        @a2.tags.reload.map(&:name)
      }.to(['tag3']).and change {
        D::My::DynamicAssociation.count
      }.by(1 - 2).and change { # 1 created, 2 destroyed
        @a1.reload.updated_at
      }.and change {
        @a2.reload.updated_at
      }.and not_change {
       @b.updated_at
      }
    end

    it 'add and remove records of an association' do
      @tag1 = D::My::Tag.create!(name: 'tag1')
      @tag2 = D::My::Tag.create!(name: 'tag2')
      @tag3 = D::My::Tag.create!(name: 'tag3')

      Dynamic::Elasticsearch.wait_for_complete(timeout: 20) do
        @a1 = D::My::Document.create!(name: 'A 1', tags: [@tag1, @tag2])
        @a2 = D::My::Document.create!(name: 'A 2', tags: [@tag1, @tag3])
      end

      expect{
        D::My::Document.differential_update(:all, {
          tags_associations_attributes: {
            _add: [{association_target_id: @tag3.id, association_target_type: 'D::My::Tag'}],
            _remove: [{association_target_id: @tag1.id, association_target_type: 'D::My::Tag'}],
          }
        })
      }.to change {
        @a1.tags.reload.map(&:name)
      }.to(['tag2', 'tag3']).and change {
        @a2.tags.reload.map(&:name)
      }.to(['tag3']).and change {
        D::My::DynamicAssociation.count
      }.by(1 - 2).and change { # 1 created, 2 destroyed
        @a1.reload.updated_at
      }.and change {
        @a2.reload.updated_at
      }
    end

  end

  describe '.where_query' do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
      @Contact = @schema.klasses.create!(
        name: 'Contact',
        attrs_attributes: [{
          name: 'last_name',
          type: 'String'
        }, {
          name: 'civility',
          values_attributes: [{
            name: 'mr'
          }, {
            name: 'mrs'
          }],
          type: 'Enum',
        }],
        options_for_indexed_json: {
          only: [
            'id',
            'last_name',
            'civility'
          ],
        }
      )
      @schema.load

      @dashboard = D::My::R::Dashboard.create!(
        charts_attributes: [{
          id: '0196f262-a810-79b4-a9a1-546a203c7f3d',
          groups_attributes: [{
            source: 'attr',
            attr: 'civility',
            value_type: 'string',
            agg: 'terms',
            axis: 'x',
          }],
          type: 'Pie'
        }]
      )

      Dynamic::Elasticsearch.wait_for_complete(timeout: 20) do
        @contact1 = D::My::Contact.create!(last_name: 'Alpha', civility: 'mr')
        @contact2 = D::My::Contact.create!(last_name: 'Alpha', civility: 'mrs')
        @contact3 = D::My::Contact.create!(last_name: 'Beta', civility: 'mr')
        @contact4 = D::My::Contact.create!(last_name: 'Beta', civility: 'mrs')
      end
    end

    it 'global search should filter records ' do
      expect(
        D::My::Contact.where_query(q: 'al').all
      ).to eq [@contact1, @contact2]
    end

    it 'table filters should filter records' do
      expect(
        D::My::Contact.where_query(filters: {last_name: {contains: 'al'}}).all.to_a
      ).to eq [@contact1, @contact2]
    end

    it 'chart filters should filter records' do
      expect(
        D::My::Contact.where_query('chart-203c7f3d': ['mr']).all
      ).to eq [@contact1, @contact3]
    end

  end

  describe '.as_deep_json', elasticsearch: false, sidekiq: false do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'My')
      @Contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'last_name', type: 'String'}])
      @schema.load
      @contact = D::My::Contact.create!(last_name: 'A')
    end

    it 'should return attributes' do
      expect(@contact.as_deep_json(secure: false).keys).to match_array(['id', 'last_name', 'type', 'polymorphic_name', 'created_at', 'updated_at', 'deleted_at'])
    end

    it 'should not return dynamic columns' do
      expect(@contact.as_deep_json(secure: false).keys).to_not include('s0')
    end
  end

end
