describe Select2 do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
  end

  describe 'Elasticsearch' do
    before(:each) do
      class MyAdapter
        include Select2::Elasticsearch
      end
    end
    after(:each) do
      Object.send(:remove_const, :MyAdapter)
    end

    context 'Dynamic::Query::Saved' do
      before(:each) do
        @schema.load
        Dynamic::Elasticsearch.wait_for_complete do
          @query = D::My::R::Query::Saved.create!(human_name: 'a')
        end
        expect(@query.__opensearch__.source).to eq(@query.as_indexed_json)
      end

      it 'should be retrieved' do
        expect(
          MyAdapter.new(@query.class, {term: 'a'}).to_json
        ).to eq(
          {
            pagination: {
              more: false
            },
            results: [
              {
                id: @query.id,
                text: @query.send(@query.class.name_attribute),
                record: @query.as_indexed_json,
              }
            ],
          }
        )
      end

    end

  end
end