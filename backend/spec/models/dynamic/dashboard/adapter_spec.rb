describe Dynamic::Dashboard::Adapter do

  let(:schema) { Dynamic::Schema.create!(name: 'Client') }
  let(:adapter) { Dynamic::Dashboard::Adapter.new(klass.const, params) }
  let(:build_schema) { schema; klass }
  let(:klass) {}
  let(:user) { User.create!(login: 'Login', email: 'email@kosmopolead.com', super_admin: true) }

  before(:each) do
    User.current = user
    build_schema
    schema.load
  end

  context "1 class with 1 enum attr" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          {
            name: 'attr',
            type: 'Enum',
            values_attributes: [
              {
                human_name_fr: 'val 1',
                human_name_en: 'val 1'
              },
              {
                human_name_fr: 'val 2',
                human_name_en: 'val 2'
              }
            ]
          }
        ]
      )
    end
    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name" => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc13",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create(attr: 'val 1')
        klass.const.create(attr: 'val 1')
        klass.const.create(attr: 'val 2')
      end
      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc13",
        name: 'dashboard',
        charts_attributes: [
        {
          id: "01973b53-b8c0-7207-9be1-caef5445beac",
          type: "Pie",
          groups_attributes: [
            {
              id: "01973b63-7418-7b29-a136-c499e389c568",
              source: "attr",
              attr: "attr",
              agg: "terms",
              value_type: "string"
            }
          ]
        }
      ])
    end

    it "should return aggregation on enum" do
      expect(adapter.as_json()[:charts]).to match_array([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: match_array([
            {key: "val 1", "01973b63-7418-7b29-a136-c499e389c568" => 2},
            {key: "val 2", "01973b63-7418-7b29-a136-c499e389c568" => 1}
          ])
        }
      ])
    end
  end

  context "1 class with multiple attributes" do

    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          {name: 'int_attr', type: 'Integer'},
          {
            name: 'enum_attr',
            type: 'Enum',
            values_attributes: [
              {human_name_fr: 'val 1', human_name_en: 'val 1'},
              {human_name_fr: 'val 2', human_name_en: 'val 2'}
            ]
          },
          {name: 'string_attr', type: 'String'},
          {name: 'date_attr', type: 'Date'}
        ]
      )
    end

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name" => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc13",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create(int_attr: 5, enum_attr: 'val 1', string_attr: 'str1', date_attr: Date.parse('2011-01-01'))
        klass.const.create(int_attr: 2, enum_attr: 'val 1', string_attr: 'str2', date_attr: Date.parse('2011-02-01'))
        klass.const.create(int_attr: 5, enum_attr: 'val 2', string_attr: 'str3', date_attr: Date.parse('2012-01-02'))
      end
      dashboard = D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc13",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445beac",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c568",
                source: "attr",
                attr: "enum_attr",
                agg: "terms",
                value_type: "string",
                axis: "x",
                position: 0,
              }
            ]
          },
          {
            id: "01973b53-bca8-71a8-8799-c6119ae76058",
            type: "Bar",
            groups_attributes: [
              {
                id: "01973b63-7be8-7a83-9d54-34e07208a9ea",
                source: "attr",
                attr: "int_attr",
                agg: "terms",
                value_type: "number",
                axis: "x",
                position: 0,
              }
            ]
          },
          {
            id: "01973b53-c090-7617-a195-7706538ef40c",
            type: "Bar",
            groups_attributes: [
              {
                id: "01973b63-7800-766a-9c2a-1122c758ebda",
                source: "attr",
                attr: "string_attr",
                agg: "terms",
                value_type: "string",
                axis: "x",
                position: 0,
              }
            ]
          },
          {
            id: "01973b53-c478-7e08-8c3a-0295669ed2f5",
            type: "Line",
            groups_attributes: [
              {
                id: "01973b63-7fd0-7a64-a3ff-01093f76f1f4",
                source: "attr",
                attr: "date_attr",
                agg: "date_histogram",
                calendar_interval: "1y",
                value_type: "date",
                axis: "x",
                position: 0,
              }
            ]
          }
        ]
      )
    end

    it "should contains aggregation of enum" do
      expect(
        adapter.as_json()[:charts].detect do |c|
          c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445beac"
        end.try(:[], :data)
      ).to match_array([
        {key: "val 1", "01973b63-7418-7b29-a136-c499e389c568" => 2},
        {key: "val 2", "01973b63-7418-7b29-a136-c499e389c568" => 1},
      ])
    end

    it "should contains aggregation of string" do
      expect(
        adapter.as_json()[:charts].detect do |c|
          c[:uuid] == "01973b53-c090-7617-a195-7706538ef40c"
        end.try(:[], :data)
      ).to match_array([
        {key: "str1", "01973b63-7800-766a-9c2a-1122c758ebda" => 1},
        {key: "str2", "01973b63-7800-766a-9c2a-1122c758ebda" => 1},
        {key: "str3", "01973b63-7800-766a-9c2a-1122c758ebda" => 1},
      ])
    end

    it "should contains aggregation of integer" do
      expect(
        adapter.as_json()[:charts].detect do |c|
          c[:uuid] == "01973b53-bca8-71a8-8799-c6119ae76058"
        end.try(:[], :data)
      ).to match_array([
        {key: 5, "01973b63-7be8-7a83-9d54-34e07208a9ea" => 2},
        {key: 2, "01973b63-7be8-7a83-9d54-34e07208a9ea" => 1}
      ])
    end

    it "should contains aggregation of date" do
      expect(
        adapter.as_json()[:charts].detect do |c|
          c[:uuid] == "01973b53-c478-7e08-8c3a-0295669ed2f5"
        end.try(:[], :data)
      ).to match_array([
        {key: DateTime.new(2011,01,01,0,0,0,'+01:00').to_i*1000 , "01973b63-7fd0-7a64-a3ff-01093f76f1f4" => 2},
        {key: DateTime.new(2012,01,01,0,0,0,'+01:00').to_i*1000 , "01973b63-7fd0-7a64-a3ff-01093f76f1f4" => 1}
      ])
    end

    it "should return all aggregations at once" do
      expect(adapter.as_json()[:charts]).to match_array([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: match_array([
            {key: "val 1", "01973b63-7418-7b29-a136-c499e389c568" => 2},
            {key: "val 2", "01973b63-7418-7b29-a136-c499e389c568" => 1}
          ])
        },
        {
          uuid: "01973b53-c090-7617-a195-7706538ef40c",
          data: match_array([
            {key: "str1", "01973b63-7800-766a-9c2a-1122c758ebda" => 1},
            {key: "str2", "01973b63-7800-766a-9c2a-1122c758ebda" => 1},
            {key: "str3", "01973b63-7800-766a-9c2a-1122c758ebda" => 1}
          ])
        },
        {
          uuid: "01973b53-bca8-71a8-8799-c6119ae76058",
          data: match_array([
            {key: 5, "01973b63-7be8-7a83-9d54-34e07208a9ea" => 2},
            {key: 2, "01973b63-7be8-7a83-9d54-34e07208a9ea" => 1}
          ])
        },
        {
          uuid: "01973b53-c478-7e08-8c3a-0295669ed2f5",
          data: match_array([
            {key: DateTime.new(2011,01,01,0,0,0,'+01:00').to_i*1000 , "01973b63-7fd0-7a64-a3ff-01093f76f1f4" => 2},
            {key: DateTime.new(2012,01,01,0,0,0,'+01:00').to_i*1000 , "01973b63-7fd0-7a64-a3ff-01093f76f1f4" => 1}
          ])
        }
      ])
    end

  end

  context "2 classes with associations" do
    let(:build_schema) { [associated_klass, klass] }
    let(:associated_klass) { schema.klasses.create(name: "AssociatedKlass", attrs_attributes: [{name: "name", type: "String"}]) }
    let(:klass) { schema.klasses.create(name: "Klass", associations_attributes: [{name: association_name, target_klass_id: associated_klass.id, type: association_type}], options_for_indexed_json: { include: { associated_klass: { only: ['name'] }, associated_klasses: { only: ['name'] } } }) }
    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name" => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc13",
      }.with_indifferent_access
    end

    before(:each) do
      @ak1 = associated_klass.const.create(name: "name 1")
      @ak2 = associated_klass.const.create(name: "name 2")
      @ak3 = associated_klass.const.create(name: "name 3")
      @ak4 = associated_klass.const.create(name: "name 4")
      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc13",
        name: 'dashboard',
        charts_attributes: [
        {
          id: "01973b53-b8c0-7207-9be1-caef5445beac",
          type: "Pie",
          groups_attributes: [
            {
              id: "01973b63-7418-7b29-a136-c499e389c568",
              source: "attr",
              attr: "#{association_name}.name",
              agg: "terms",
              value_type: "string"
            }
          ]
        }
      ])
    end

    context "Belongs To" do
      let(:association_name) { "associated_klass" }
      let(:association_type) { "BelongsTo" }
      before(:each) do
        Dynamic::Elasticsearch.wait_for_complete do
          klass.const.create(associated_klass: @ak1)
          klass.const.create(associated_klass: @ak1)
          klass.const.create(associated_klass: @ak2)
          klass.const.create(associated_klass: @ak3)
        end
      end

      it "should return aggregations for associated_klass.name" do
        expect(adapter.as_json()[:charts]).to match_array([
          {
            uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
            data: match_array([
              {key: "name 1", "01973b63-7418-7b29-a136-c499e389c568" => 2},
              {key: "name 2", "01973b63-7418-7b29-a136-c499e389c568" => 1},
              {key: "name 3", "01973b63-7418-7b29-a136-c499e389c568" => 1}
            ])
          }
        ])
      end

    end

    context "Has Many" do
      let(:association_name) { "associated_klasses" }
      let(:association_type) { "HasMany" }
      before(:each) do
        Dynamic::Elasticsearch.wait_for_complete do
          klass.const.create(associated_klasses: [@ak1, @ak3])
          klass.const.create(associated_klasses: [@ak1, @ak2])
          klass.const.create(associated_klasses: [@ak3, @ak4])
          klass.const.create(associated_klasses: [@ak1, @ak4])
        end
      end

      it "should return aggregations for associated_klasses.name" do
        expect(adapter.as_json()[:charts]).to match_array([
          {
            uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
            data: match_array([
              {key: "name 1", "01973b63-7418-7b29-a136-c499e389c568" => 3},
              {key: "name 2", "01973b63-7418-7b29-a136-c499e389c568" => 1},
              {key: "name 3", "01973b63-7418-7b29-a136-c499e389c568" => 2},
              {key: "name 4", "01973b63-7418-7b29-a136-c499e389c568" => 2}
            ])
          }
        ])
      end
    end

  end

  context "3 classes with 2 nested associations" do
    # klass -> associated_klass -> inner_associated_klass
    let(:build_schema) { [inner_associated_klass, associated_klass, klass] }
    let(:inner_associated_klass) do
      schema.klasses.create(name: "InnerAssociatedKlass", attrs_attributes: [{name: "name", type: "String"}])
    end
    let(:associated_klass) do
      schema.klasses.create(
        name: "AssociatedKlass",
        associations_attributes: [
          {name: "inner_klasses", target_klass_id: inner_associated_klass.id, type: "HasMany"}
        ]
      )
    end
    let(:klass) do
      schema.klasses.create(
        name: "Klass",
        associations_attributes: [
          {
            name: "associated_klasses",
            target_klass_id: associated_klass.id,
            type: "HasMany"
          }
        ],
        options_for_indexed_json: {include: {associated_klasses: {include: {inner_klasses: {only: [:name]}}}}}
      )
    end

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name" => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc13",
      }.with_indifferent_access
    end

    before(:each) do
      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc13",
        name: 'dashboard',
        charts_attributes: [
        {
          id: "01973b53-b8c0-7207-9be1-caef5445beac",
          type: "Pie",
          groups_attributes: [
            {
              id: "01973b63-7418-7b29-a136-c499e389c568",
              source: "attr",
              attr: "associated_klasses.inner_klasses.name",
              agg: "terms",
              value_type: "string",
              axis: "x",
              position: 0,
            }
          ]
        }
      ])

      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create(associated_klasses_attributes: [
          {inner_klasses_attributes: [{name: "name1"}, {name: "name2"}]},
          {inner_klasses_attributes: [{name: "name1"}, {name: "name3"}]},
        ])
        klass.const.create(associated_klasses_attributes: [
          {inner_klasses_attributes: [{name: "name1"}, {name: "name2"}]},
          {inner_klasses_attributes: [{name: "name2"}, {name: "name4"}]},
        ])
        klass.const.create(associated_klasses_attributes: [
          {inner_klasses_attributes: [{name: "name1"}, {name: "name3"}]},
          {inner_klasses_attributes: [{name: "name3"}, {name: "name4"}]},
        ])
      end
    end

    it "should return aggregations for associated_klasses.inner_klasses.name" do
      expect(adapter.as_json()[:charts]).to match_array([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: match_array([
            {key: "name1", "01973b63-7418-7b29-a136-c499e389c568" => 3},
            {key: "name2", "01973b63-7418-7b29-a136-c499e389c568" => 2},
            {key: "name3", "01973b63-7418-7b29-a136-c499e389c568" => 2},
            {key: "name4", "01973b63-7418-7b29-a136-c499e389c568" => 2}
          ])
        }
      ])
    end

  end

  context "charts with missing values" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          {
            name: 'category',
            type: 'String',
          },
          {
            name: 'quantity',
            type: 'Integer',
          }
        ]
      )
    end

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name" => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc55",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create!(category: 'A', quantity: 1)
        klass.const.create!(category: 'A', quantity: 10)
        klass.const.create!(category: 'A', quantity: 100)
        klass.const.create!(category: 'B', quantity: 10)
        klass.const.create!(category: 'B', quantity: 15)
        klass.const.create!(quantity: 2)
        klass.const.create!(quantity: 3)
        klass.const.create!(quantity: 4)
        klass.const.create!(quantity: 5)
      end

      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc55",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445beac",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c568",
                source: "attr",
                attr: "category",
                agg: "terms",
                value_type: "string",
              }
            ]
          }
        ]
      )
    end

    it "returns counts for categories including empty values" do
      expect(adapter.as_json()[:charts]).to match_array([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: match_array([
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "missing", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
          ])
        }
      ])
    end
  end

  context "charts with missing values in various attribute types" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'category',          type: 'String'  },
          { name: 'available_store',   type: 'Boolean' },
          { name: 'quantity',          type: 'Integer' },
          { name: 'price',             type: 'Float'   },
          { name: 'issued_at',         type: 'Date'    },
        ]
      )
    end

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name"  => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc55",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create!(category: 'A', available_store: true,  quantity: 1, price: 1.5, issued_at: Date.parse('2025-02-01'))
        klass.const.create!(category: 'A', available_store: true,  quantity: 1, price: 2.5, issued_at: Date.parse('2025-02-01'))
        klass.const.create!(category: 'B', available_store: false, quantity: 3, price: 3.5, issued_at: Date.parse('2025-03-01'))
        klass.const.create!()
        klass.const.create!()
        klass.const.create!()
      end
      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc55",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a333",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c783",
                source: "attr",
                attr: "quantity",
                agg: "terms",
                value_type: "number",
              }
            ]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a777",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c567",
                source: "attr",
                attr: "issued_at",
                agg: "terms",
                value_type: "date",
              }
            ]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445b888",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c566",
                source: "attr",
                attr: "category",
                agg: "terms",
                value_type: "string",
              }
            ]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445b999",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c565",
                source: "attr",
                attr: "available_store",
                agg: "terms",
                value_type: "boolean",
              }
            ]
          }
        ]
      )
    end

    it "should handle missing values correctly for integer attributes" do
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a333" }[:data]

      expect(chart_data).to match_array([
        { key: 1, "01973b63-7418-7b29-a136-c499e389c783" => 2 },
        { key: 3, "01973b63-7418-7b29-a136-c499e389c783" => 1 },
        { key: "missing", "01973b63-7418-7b29-a136-c499e389c783" => 3 },
      ])
    end

    it "should handle missing values correctly for boolean attributes" do
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445b999" }[:data]

      expect(chart_data).to match_array([
        { key: 1, "01973b63-7418-7b29-a136-c499e389c565" => 2 },
        { key: 0, "01973b63-7418-7b29-a136-c499e389c565" => 1 },
        { key: "missing", "01973b63-7418-7b29-a136-c499e389c565" => 3 },
      ])
    end

    it "should handle missing values correctly for date attributes" do
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a777" }[:data]

      expect(chart_data).to match_array([
        { key: 1738368000000, "01973b63-7418-7b29-a136-c499e389c567" => 2 },
        { key: 1740787200000, "01973b63-7418-7b29-a136-c499e389c567" => 1 },
        { key: "missing", "01973b63-7418-7b29-a136-c499e389c567" => 3 },
      ])
    end

    it "should handle missing values correctly for string attributes" do
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445b888" }[:data]

      expect(chart_data).to match_array([
        { key: 'A', "01973b63-7418-7b29-a136-c499e389c566" => 2 },
        { key: 'B', "01973b63-7418-7b29-a136-c499e389c566" => 1 },
        { key: "missing", "01973b63-7418-7b29-a136-c499e389c566" => 3 },
      ])
    end
  end

  context "charts with sub aggregation and missing values in various attribute types" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'category',          type: 'String'  },
          { name: 'available_store',   type: 'Boolean' },
          { name: 'quantity',          type: 'Integer' },
          { name: 'price',             type: 'Float'   },
          { name: 'issued_at',         type: 'Date'    },
        ]
      )
    end

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name"  => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc55",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create!(category: 'A', available_store: true,  quantity: 1, price: 1.5, issued_at: Date.parse('2025-02-01'))
        klass.const.create!(category: 'A', available_store: true,  quantity: 1, price: 2.5, issued_at: Date.parse('2025-02-01'))
        klass.const.create!(category: 'B', available_store: false, quantity: 3, price: 3.5, issued_at: Date.parse('2025-03-01'))
        klass.const.create!(quantity: 3, price: 4.5, issued_at: Date.parse('2025-04-03'))
        klass.const.create!(price: 7.5, issued_at: Date.parse('2025-12-02'))
        klass.const.create!(available_store: false, issued_at: Date.parse('2025-08-09'))
        klass.const.create!(available_store: false, quantity: 20)
        klass.const.create!(available_store: true, quantity: 10, price: 16, issued_at: Date.parse('2025-08-09'))
      end
      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc55",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a111",
            type: "Line",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c111",
                source: "attr",
                attr: "category",
                agg: "terms",
                value_type: "string",
                axis: "x",
                position: 0,
              },
              {
                id: "01973b63-7418-7b29-a136-c499e389c112",
                source: "attr",
                attr: "quantity",
                agg: "avg",
                value_type: "number",
                axis: "y",
                position: 1,
              }
            ]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a222",
            type: "Line",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c221",
                source: "attr",
                attr: "category",
                agg: "terms",
                value_type: "string",
                axis: "x",
                position: 0,
              },
              {
                id: "01973b63-7418-7b29-a136-c499e389c222",
                source: "attr",
                attr: "price",
                agg: "min",
                value_type: "number",
                axis: "y",
                position: 1,
              }
            ]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a333",
            type: "Line",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c331",
                source: "attr",
                attr: "category",
                agg: "terms",
                value_type: "string",
                axis: "x",
                position: 0,
              },
              {
                id: "01973b63-7418-7b29-a136-c499e389c332",
                source: "attr",
                attr: "issued_at",
                agg: "cardinality",
                value_type: "date",
                axis: "y",
                position: 1,
              }
            ]
          }
        ]
      )
    end

    it "should return avg(quantity) per category with a missing category key" do
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a111" }[:data]

      expect(chart_data).to match_array([
        { key: 'A', "01973b63-7418-7b29-a136-c499e389c111" => 2, "01973b63-7418-7b29-a136-c499e389c112" => 1.0 },
        { key: 'B', "01973b63-7418-7b29-a136-c499e389c111" => 1,"01973b63-7418-7b29-a136-c499e389c112" => 3.0 },
        { key: 'missing', "01973b63-7418-7b29-a136-c499e389c111" => 5,"01973b63-7418-7b29-a136-c499e389c112" => 11.0 },
      ])
    end

    it "should return min(price) per category with missing category key" do
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a222" }[:data]

      expect(chart_data).to match_array([
        { key: 'A', "01973b63-7418-7b29-a136-c499e389c221"=> 2, "01973b63-7418-7b29-a136-c499e389c222" => 1.5 },
        { key: 'B', "01973b63-7418-7b29-a136-c499e389c221"=> 1, "01973b63-7418-7b29-a136-c499e389c222" => 3.5 },
        { key: 'missing', "01973b63-7418-7b29-a136-c499e389c221"=> 5, "01973b63-7418-7b29-a136-c499e389c222" => 4.5 },
      ])
    end

    it "returns cardinality(issued_at) per category with missing category key" do
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a333" }[:data]

      expect(chart_data).to match_array([
        { key: 'A', "01973b63-7418-7b29-a136-c499e389c331"=> 2,"01973b63-7418-7b29-a136-c499e389c332" => 1 },
        { key: 'B', "01973b63-7418-7b29-a136-c499e389c331"=> 1, "01973b63-7418-7b29-a136-c499e389c332" => 1 },
        { key: 'missing', "01973b63-7418-7b29-a136-c499e389c331"=> 5, "01973b63-7418-7b29-a136-c499e389c332" => 3 },
      ])
    end
  end

  context "Test the sort functionality for chart data" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          {
            name: 'category',
            type: 'String'
          },
          {
            name: 'quantity',
            type: 'Integer'
          }
        ]
      )
      end

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name" => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc55",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create!(category: 'A', quantity: 1)
        klass.const.create!(category: 'A', quantity: 10)
        klass.const.create!(category: 'A', quantity: 0)
        klass.const.create!(category: 'B', quantity: 10)
        klass.const.create!(category: 'B', quantity: 1)
        klass.const.create!(category: 'C', quantity: 2)
        klass.const.create!(category: 'C', quantity: 3)
        klass.const.create!(category: 'C', quantity: 4)
        klass.const.create!(category: 'C', quantity: 5)
      end

      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc55",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445beac",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c568",
                source: "attr",
                attr: "category",
                agg: "terms",
                value_type: "string",
              }
            ]
          }
        ]
      )
    end

    it "returns terms sorted in descending lexical order when x is 'desc'" do
      params[:search_query] = {
        "chart-5445beac" => {"order" => {"x": 'desc', "y": nil}}
      }
      expect(adapter.as_json()[:charts]).to eq([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: [
            { key: "C", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
          ]
        }
      ])
    end
    it "returns terms sorted in ascending lexical order when x is 'asc'" do
      params[:search_query] = {
        "chart-5445beac" => {"order" => {"x": 'asc', "y": nil}}
      }
      expect(adapter.as_json()[:charts]).to eq([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: [
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "C", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
          ]
        }
      ])
    end
    it "returns buckets sorted by count ascending when y is 'asc'" do
      params[:search_query] = {
        "chart-5445beac" => {"order" => {"x": nil, "y": 'asc'}}
      }
      expect(adapter.as_json()[:charts]).to eq([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: [
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
            { key: "C", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
          ]
        }
      ])
    end
    it "returns buckets sorted by count descending when y is 'desc'" do
      params[:search_query] = {
        "chart-5445beac" => {"order" => {"x": nil, "y": 'desc'}}
      }
      expect(adapter.as_json()[:charts]).to eq([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: [
            { key: "C", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
          ]
        }
      ])
    end
  end

  context "sort functionality on chart when there is a sub-aggregation" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'category', type: 'String' },
          { name: 'quantity', type: 'Integer' },
          { name: 'price', type: 'Integer' },
          { name: 'issued_at', type: 'Date' }
        ]
      )
    end

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name" => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc55",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create!(category: 'A', quantity: 57, price: 100, issued_at: '2025-01-01')
        klass.const.create!(category: 'A', quantity: 0, price: 150, issued_at: '2025-01-02')
        klass.const.create!(category: 'A', quantity: 0, price: 150, issued_at: '2025-01-03')
        klass.const.create!(category: 'B', quantity: 40, price: 200, issued_at: '2025-01-01')
        klass.const.create!(category: 'B', quantity: 30, price: 50, issued_at: '2025-01-03')
        klass.const.create!(category: 'C', quantity: 50, price: 300, issued_at: '2025-01-02')
        klass.const.create!(category: 'C', quantity: 1, price: 250, issued_at: '2025-01-03')
        klass.const.create!(category: 'C', quantity: 1, price: 250, issued_at: '2025-01-03')
        klass.const.create!(category: 'C', quantity: 1, price: 250, issued_at: '2025-01-03')
      end

      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc55",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a111",
            type: "Line",
            groups_attributes: [
              { id: "01973b63-7418-7b29-a136-c499e389c111", source: "attr", attr: "category", agg: "terms", value_type: "string", axis: "x", position: 0 },
              { id: "01973b63-7418-7b29-a136-c499e389c112", source: "attr", attr: "quantity", agg: "avg", value_type: "number", axis: "y", position: 1 }
            ]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a222",
            type: "Line",
            groups_attributes: [
              { id: "01973b63-7418-7b29-a136-c499e389c221", source: "attr", attr: "category", agg: "terms", value_type: "string", axis: "x", position: 0 },
              { id: "01973b63-7418-7b29-a136-c499e389c222", source: "attr", attr: "price", agg: "min", value_type: "number", axis: "y", position: 1 }
            ]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a333",
            type: "Line",
            groups_attributes: [
              { id: "01973b63-7418-7b29-a136-c499e389c331", source: "attr", attr: "category", agg: "terms", value_type: "string", axis: "x", position: 0 },
              { id: "01973b63-7418-7b29-a136-c499e389c332", source: "attr", attr: "issued_at", agg: "cardinality", value_type: "date", axis: "y", position: 1 }
            ]
          }
        ]
      )
    end

    it "sorts by category descending with avg quantity sub-aggregation" do
      params[:search_query] = { "chart-5445a111" => {'order' => { "x": 'desc', "y": nil }} }
      expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a111" }[:data]).to eq([
        { key: "C", "01973b63-7418-7b29-a136-c499e389c111" => 4, "01973b63-7418-7b29-a136-c499e389c112" => 13.25 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c111" => 2, "01973b63-7418-7b29-a136-c499e389c112" => 35.0 },
        { key: "A", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 19.0 },
      ])
    end

    it "sorts by category ascending with avg quantity sub-aggregation" do
      params[:search_query] = { "chart-5445a111" => {'order' => { "x": 'asc', "y": nil }} }
      expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a111" }[:data]).to eq([
        { key: "A", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 19.0 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c111" => 2, "01973b63-7418-7b29-a136-c499e389c112" => 35.0 },
        { key: "C", "01973b63-7418-7b29-a136-c499e389c111" => 4, "01973b63-7418-7b29-a136-c499e389c112" => 13.25 },
      ])
    end

    it "sorts by avg quantity ascending" do
      params[:search_query] = { "chart-5445a111" => {'order' => { "x": nil, "y": 'asc' }} }
      expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a111" }[:data]).to eq([
        { key: "C", "01973b63-7418-7b29-a136-c499e389c111" => 4, "01973b63-7418-7b29-a136-c499e389c112" => 13.25 },
        { key: "A", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 19.0 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c111" => 2, "01973b63-7418-7b29-a136-c499e389c112" => 35.0 },
      ])
    end

    it "sorts by avg quantity descending" do
      params[:search_query] = { "chart-5445a111" => {'order' => { "x": nil, "y": 'desc' }} }
      expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a111" }[:data]).to eq([
        { key: "B", "01973b63-7418-7b29-a136-c499e389c111" => 2, "01973b63-7418-7b29-a136-c499e389c112" => 35.0 },
        { key: "A", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 19.0 },
        { key: "C", "01973b63-7418-7b29-a136-c499e389c111" => 4, "01973b63-7418-7b29-a136-c499e389c112" => 13.25},
      ])
    end

    context "min price" do
      it "ascending" do
        params[:search_query] = { "chart-5445a222" => {'order' => { x: nil, y: 'asc' }} }
        expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a222" }[:data]).to eq([
          { key: "B", "01973b63-7418-7b29-a136-c499e389c221" => 2, "01973b63-7418-7b29-a136-c499e389c222" => 50 },
          { key: "A", "01973b63-7418-7b29-a136-c499e389c221" => 3, "01973b63-7418-7b29-a136-c499e389c222" => 100 },
          { key: "C", "01973b63-7418-7b29-a136-c499e389c221" => 4, "01973b63-7418-7b29-a136-c499e389c222" => 250 }
        ])
      end

      it "descending" do
        params[:search_query] = { "chart-5445a222" => {'order' => { x: nil, y: 'desc' }} }
        expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a222" }[:data]).to eq([
          { key: "C", "01973b63-7418-7b29-a136-c499e389c221" => 4, "01973b63-7418-7b29-a136-c499e389c222" => 250 },
          { key: "A", "01973b63-7418-7b29-a136-c499e389c221" => 3, "01973b63-7418-7b29-a136-c499e389c222" => 100 },
          { key: "B", "01973b63-7418-7b29-a136-c499e389c221" => 2, "01973b63-7418-7b29-a136-c499e389c222" => 50 }
        ])
      end
    end

    context "cardinality issued_at" do
      it "ascending" do
        params[:search_query] = { "chart-5445a333" => {'order' => { x: nil, y: 'asc' }} }
        expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a333" }[:data]).to eq([
          { key: "B", "01973b63-7418-7b29-a136-c499e389c331" => 2, "01973b63-7418-7b29-a136-c499e389c332" => 2 },
          { key: "C", "01973b63-7418-7b29-a136-c499e389c331" => 4, "01973b63-7418-7b29-a136-c499e389c332" => 2 },
          { key: "A", "01973b63-7418-7b29-a136-c499e389c331" => 3, "01973b63-7418-7b29-a136-c499e389c332" => 3 },
        ])
      end

      it "descending" do
        params[:search_query] = { "chart-5445a333" => {'order' => { x: nil, y: 'desc' }} }
        expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a333" }[:data]).to eq([
          { key: "A", "01973b63-7418-7b29-a136-c499e389c331" => 3, "01973b63-7418-7b29-a136-c499e389c332" => 3 },
          { key: "B", "01973b63-7418-7b29-a136-c499e389c331" => 2, "01973b63-7418-7b29-a136-c499e389c332" => 2 },
          { key: "C", "01973b63-7418-7b29-a136-c499e389c331" => 4, "01973b63-7418-7b29-a136-c499e389c332" => 2 },
        ])
      end
    end

  end

  context "sort functionality on chart when there is a sub-aggregation and to make sure the y sort is applied on all the data and not only the 10 first aggregated data" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'category', type: 'String' },
          { name: 'quantity', type: 'Integer' },
          { name: 'price', type: 'Integer' },
          { name: 'issued_at', type: 'Date' }
        ]
      )
    end

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name" => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc55",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create!(category: 'A', quantity: 57, price: 100, issued_at: '2025-01-01')
        klass.const.create!(category: 'A', quantity: 0, price: 150, issued_at: '2025-01-02')
        klass.const.create!(category: 'A', quantity: 0, price: 150, issued_at: '2025-01-03')
        klass.const.create!(category: 'B', quantity: 40, price: 200, issued_at: '2025-01-01')
        klass.const.create!(category: 'B', quantity: 30, price: 50, issued_at: '2025-01-03')
        klass.const.create!(category: 'C', quantity: 50, price: 300, issued_at: '2025-01-02')
        klass.const.create!(category: 'C', quantity: 1, price: 250, issued_at: '2025-01-03')
        klass.const.create!(category: 'C', quantity: 1, price: 250, issued_at: '2025-01-03')
        klass.const.create!(category: 'D', quantity: 10, price: 400, issued_at: '2025-01-03')
        klass.const.create!(category: 'E', quantity: 20, price: 250, issued_at: '2025-01-03')
        klass.const.create!(category: 'F', quantity: 14, price: 20, issued_at: '2025-01-03')
        klass.const.create!(category: 'G', quantity: 12, price: 50, issued_at: '2025-01-03')
        klass.const.create!(category: 'H', quantity: 100, price: 60, issued_at: '2025-01-03')
        klass.const.create!(category: 'I', quantity: 10, price: 200, issued_at: '2025-01-03')
        klass.const.create!(category: 'J', quantity: 5, price: 10, issued_at: '2025-01-03')
        klass.const.create!(category: 'K', quantity: 2, price: 50, issued_at: '2025-01-03')
        klass.const.create!(category: 'L', quantity: 1, price: 1000, issued_at: '2025-01-03')
      end

      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc55",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a111",
            type: "Line",
            groups_attributes: [
              { id: "01973b63-7418-7b29-a136-c499e389c111", source: "attr", attr: "category", agg: "terms", value_type: "string", axis: "x", position: 0 },
              { id: "01973b63-7418-7b29-a136-c499e389c112", source: "attr", attr: "quantity", agg: "avg", value_type: "number", axis: "y", position: 1 }
            ]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a222",
            type: "Line",
            groups_attributes: [
              { id: "01973b63-7418-7b29-a136-c499e389c221", source: "attr", attr: "category", agg: "terms", value_type: "string", axis: "x", position: 0 },
              { id: "01973b63-7418-7b29-a136-c499e389c222", source: "attr", attr: "price", agg: "min", value_type: "number", axis: "y", position: 1 }
            ]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a333",
            type: "Line",
            groups_attributes: [
              { id: "01973b63-7418-7b29-a136-c499e389c331", source: "attr", attr: "category", agg: "terms", value_type: "string", axis: "x", position: 0 },
              { id: "01973b63-7418-7b29-a136-c499e389c332", source: "attr", attr: "issued_at", agg: "cardinality", value_type: "date", axis: "y", position: 1 }
            ]
          }
        ]
      )
    end

    it "sorts by avg quantity ascending" do
      params[:search_query] = { "chart-5445a111" => {'order' => { "x": nil, "y": 'asc' }} }
      expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a111" }[:data]).to eq([
        { key: "L", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 1.0 },
        { key: "K", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 2.0 },
        { key: "J", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 5.0 },
        { key: "D", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 10.0 },
        { key: "I", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 10.0 },
        { key: "G", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 12.0 },
        { key: "F", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 14.0 },
        { key: "C", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 17.333333333333332 },
        { key: "A", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 19.0 },
        { key: "E", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 20.0 },
      ])
    end

    it "sorts by avg quantity descending" do
      params[:search_query] = { "chart-5445a111" => {'order' => { "x": nil, "y": 'desc' }} }
      expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a111" }[:data]).to eq([
        { key: "H", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 100.0 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c111" => 2, "01973b63-7418-7b29-a136-c499e389c112" => 35.0 },
        { key: "E", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 20.0 },
        { key: "A", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 19.0 },
        { key: "C", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 17.333333333333332 },
        { key: "F", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 14.0 },
        { key: "G", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 12.0 },
        { key: "D", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 10.0 },
        { key: "I", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 10.0 },
        { key: "J", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 5.0 },
      ])
    end

    context "min price" do
      it "ascending" do
        params[:search_query] = { "chart-5445a222" => {'order' => { x: nil, y: 'asc' }} }
        expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a222" }[:data]).to eq([
          { key: "J", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 10.0 },
          { key: "F", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 20.0 },
          { key: "B", "01973b63-7418-7b29-a136-c499e389c221" => 2, "01973b63-7418-7b29-a136-c499e389c222" => 50.0 },
          { key: "G", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 50.0 },
          { key: "K", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 50.0 },
          { key: "H", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 60.0 },
          { key: "A", "01973b63-7418-7b29-a136-c499e389c221" => 3, "01973b63-7418-7b29-a136-c499e389c222" => 100.0 },
          { key: "I", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 200.0 },
          { key: "C", "01973b63-7418-7b29-a136-c499e389c221" => 3, "01973b63-7418-7b29-a136-c499e389c222" => 250.0 },
          { key: "E", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 250.0 },
        ])
      end

      it "descending" do
        params[:search_query] = { "chart-5445a222" => {'order' => { x: nil, y: 'desc' }} }
        expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a222" }[:data]).to eq([
          { key: "L", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 1000.0 },
          { key: "D", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 400.0 },
          { key: "C", "01973b63-7418-7b29-a136-c499e389c221" => 3, "01973b63-7418-7b29-a136-c499e389c222" => 250.0 },
          { key: "E", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 250.0 },
          { key: "I", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 200.0 },
          { key: "A", "01973b63-7418-7b29-a136-c499e389c221" => 3, "01973b63-7418-7b29-a136-c499e389c222" => 100.0 },
          { key: "H", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 60.0 },
          { key: "B", "01973b63-7418-7b29-a136-c499e389c221" => 2, "01973b63-7418-7b29-a136-c499e389c222" => 50.0 },
          { key: "G", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 50.0 },
          { key: "K", "01973b63-7418-7b29-a136-c499e389c221" => 1, "01973b63-7418-7b29-a136-c499e389c222" => 50.0 },
        ])
      end
    end

  end

  context "sort functionality on chart when there is more than one sub-aggregation" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'category', type: 'String' },
          { name: 'quantity', type: 'Integer' },
          { name: 'price', type: 'Integer' },
          { name: 'issued_at', type: 'Date' }
        ]
      )
    end

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name" => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc55",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create!(category: 'A', quantity: 50, price: 200, issued_at: '2025-01-01')
        klass.const.create!(category: 'A', quantity: 100, price: 150, issued_at: '2025-01-02')
        klass.const.create!(category: 'A', quantity: 60, price: 150, issued_at: '2025-01-03')
        klass.const.create!(category: 'B', quantity: 5, price: 300, issued_at: '2025-01-02')
        klass.const.create!(category: 'B', quantity: 10, price: 250, issued_at: '2025-01-03')
        klass.const.create!(category: 'B', quantity: 15, price: 250, issued_at: '2025-01-03')
        klass.const.create!(category: 'C', quantity: 70, price: 100, issued_at: '2025-01-01')
        klass.const.create!(category: 'C', quantity: 70, price: 150, issued_at: '2025-01-03')
        klass.const.create!(category: 'D', quantity: 10, price: 400, issued_at: '2025-01-03')
        klass.const.create!(category: 'I', quantity: 10, price: 400, issued_at: '2025-01-03')
      end

      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc55",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a111",
            type: "Line",
            groups_attributes: [
              { id: "01973b63-7418-7b29-a136-c499e389c111", source: "attr", attr: "category", agg: "terms", value_type: "string", axis: "x", position: 0 },
              { id: "01973b63-7418-7b29-a136-c499e389c112", source: "attr", attr: "quantity", agg: "avg", value_type: "number", axis: "y", position: 1 },
              { id: "01973b63-7418-7b29-a136-c499e389c113", source: "attr", attr: "price", agg: "min", value_type: "number", axis: "y", position: 2 }
            ]
          }
        ]
      )
    end

    it "sorts by avg quantity asc then min price asc" do
      params[:search_query] = { "chart-5445a111" => {'order' => { "x": nil, "y": 'asc' }} }
      expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a111" }[:data]).to eq([
        { key: "B", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 10.0, "01973b63-7418-7b29-a136-c499e389c113" => 250.0},
        { key: "D", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 10.0, "01973b63-7418-7b29-a136-c499e389c113" => 400.0},
        { key: "I", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 10.0, "01973b63-7418-7b29-a136-c499e389c113" => 400.0},
        { key: "C", "01973b63-7418-7b29-a136-c499e389c111" => 2, "01973b63-7418-7b29-a136-c499e389c112" => 70.0, "01973b63-7418-7b29-a136-c499e389c113" => 100.0},
        { key: "A", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 70.0, "01973b63-7418-7b29-a136-c499e389c113" => 150.0},
      ])
    end

    it "sorts by avg quantity desc then min price desc" do
      params[:search_query] = { "chart-5445a111" => {'order' => { "x": nil, "y": 'desc' }} }
      expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a111" }[:data]).to eq([
        { key: "A", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 70.0, "01973b63-7418-7b29-a136-c499e389c113" => 150.0},
        { key: "C", "01973b63-7418-7b29-a136-c499e389c111" => 2, "01973b63-7418-7b29-a136-c499e389c112" => 70.0, "01973b63-7418-7b29-a136-c499e389c113" => 100.0},
        { key: "D", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 10.0, "01973b63-7418-7b29-a136-c499e389c113" => 400.0},
        { key: "I", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 10.0, "01973b63-7418-7b29-a136-c499e389c113" => 400.0},
        { key: "B", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 10.0, "01973b63-7418-7b29-a136-c499e389c113" => 250.0},
      ])
    end

    it "sorts by avg quantity desc then min price desc then desc term category" do
      params[:search_query] = { "chart-5445a111" => {'order' => { "x": 'desc', "y": 'desc' }} }
      expect(adapter.as_json()[:charts].find { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a111" }[:data]).to eq([
        { key: "A", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 70.0, "01973b63-7418-7b29-a136-c499e389c113" => 150.0},
        { key: "C", "01973b63-7418-7b29-a136-c499e389c111" => 2, "01973b63-7418-7b29-a136-c499e389c112" => 70.0, "01973b63-7418-7b29-a136-c499e389c113" => 100.0},
        { key: "I", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 10.0, "01973b63-7418-7b29-a136-c499e389c113" => 400.0},
        { key: "D", "01973b63-7418-7b29-a136-c499e389c111" => 1, "01973b63-7418-7b29-a136-c499e389c112" => 10.0, "01973b63-7418-7b29-a136-c499e389c113" => 400.0},
        { key: "B", "01973b63-7418-7b29-a136-c499e389c111" => 3, "01973b63-7418-7b29-a136-c499e389c112" => 10.0, "01973b63-7418-7b29-a136-c499e389c113" => 250.0},
      ])
    end
  end

  context "exhaustive sort combinations for chart data" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'category', type: 'String' },
          { name: 'quantity', type: 'Integer' }
        ]
      )
    end

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name"  => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc55",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create!(category: 'A', quantity: 1)
        klass.const.create!(category: 'A', quantity: 10)
        klass.const.create!(category: 'A', quantity: 0)
        klass.const.create!(category: 'B', quantity: 10)
        klass.const.create!(category: 'B', quantity: 1)
        klass.const.create!(category: 'C', quantity: 2)
        klass.const.create!(category: 'C', quantity: 3)
        klass.const.create!(category: 'C', quantity: 4)
        klass.const.create!(category: 'C', quantity: 5)
        klass.const.create!(category: 'D', quantity: 40)
        klass.const.create!(category: 'D', quantity: 21)
      end

      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc55",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445beac",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c568",
                source: "attr",
                attr: "category",
                agg: "terms",
                value_type: "string",
              }
            ]
          }
        ]
      )
    end

    it "x asc + y asc" do
      params[:search_query] = {
        "chart-5445beac" => { 'order' => { "x": 'asc', "y": 'asc' } }
      }
      expect(adapter.as_json()[:charts]).to eq([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: [
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "D", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
            { key: "C", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
          ]
        }
      ])
    end

    it "x desc + y desc" do
      params[:search_query] = {
        "chart-5445beac" => { 'order' => { "x": 'desc', "y": 'desc' } }
      }
      expect(adapter.as_json()[:charts]).to eq([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: [
            { key: "C", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
            { key: "D", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
          ]
        }
      ])
    end

    it "only x present (x: 'asc', y missing)" do
      params[:search_query] = {
        "chart-5445beac" => { 'order' => { "x": 'asc' } } # y omitted
      }
      expect(adapter.as_json()[:charts]).to eq([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: [
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "C", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
            { key: "D", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
          ]
        }
      ])
    end

    it "only y present (y: 'desc', x missing)" do
      params[:search_query] = {
        "chart-5445beac" => { 'order' => { "y": 'desc' } }
      }
      expect(adapter.as_json()[:charts]).to eq([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: [
            { key: "C", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "D", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
          ]
        }
      ])
    end

    it "both missing (empty sort hash)" do
      params[:search_query] = {
        "chart-5445beac" => { 'order' => {} }
      }
      expect(adapter.as_json()[:charts]).to eq([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: [
            { key: "C", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "D", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
          ]
        }
      ])
    end

    it "no sort param at all" do
      params.delete(:search_query)
      expect(adapter.as_json()[:charts]).to eq([
        {
          uuid: "01973b53-b8c0-7207-9be1-caef5445beac",
          data: [
            { key: "C", "01973b63-7418-7b29-a136-c499e389c568" => 4 },
            { key: "A", "01973b63-7418-7b29-a136-c499e389c568" => 3 },
            { key: "B", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
            { key: "D", "01973b63-7418-7b29-a136-c499e389c568" => 2 },
          ]
        }
      ])
    end
  end

  context "range agg filter, exclusion and order on a chart" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'category', type: 'String' },
          { name: 'price',    type: 'Integer' },
          { name: 'quantity', type: 'Integer' },
        ]
      )
    end

    let(:params) do
      {
        "schema_name"  => "Client",
        "klass_name"   => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc55",
      }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create!(category: 'A', price: 50,  quantity: 1)
        klass.const.create!(category: 'A', price: 150, quantity: 2)
        klass.const.create!(category: 'A', price: 250, quantity: 3)
        klass.const.create!(category: 'B', price: 250, quantity: 3)
        klass.const.create!(category: 'B', price: 350, quantity: 4)
        klass.const.create!(category: 'C', price: 450, quantity: 5)
        klass.const.create!(category: 'C', price: 550, quantity: 6)
      end

      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc55",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a001",
            type: "Bar",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c001",
                source: "attr",
                attr: "price",
                agg: "range",
                value_type: "number",
                axis: "x",
                position: 0,
                ranges_attributes: [
                  { from: 0,   to: 200 },
                  { from: 200, to: 400 },
                  { from: 400, to: 600 },
                ]
              }
            ]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445a002",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c002",
                source: "attr",
                attr: "category",
                agg: "terms",
                value_type: "string",
                axis: "x",
                position: 0,
              }
            ]
          },
        ]
      )
    end

    it "filters to records whose price falls in a single selected range bucket" do
      params[:search_query] = {"chart-5445a001" => { "filters" => ["0-200"] }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a002"}[:data]

      expect(chart_data).to match_array([
         { key: "A", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
      ])
    end

    it "filters to records whose price falls in any of multiple selected range buckets" do
      params[:search_query] = {"chart-5445a001" => { "filters" => ["0-200", "200-400"] }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a002"}[:data]

      expect(chart_data).to match_array([
        { key: "A", "01973b63-7418-7b29-a136-c499e389c002" => 3 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
      ])
    end

    it "skips a range string whose second bound is empty and returns unfiltered results" do
      params[:search_query] = {"chart-5445a001" => { "filters" => ["0-"] }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a002"}[:data]

      expect(chart_data).to match_array([
        { key: "A", "01973b63-7418-7b29-a136-c499e389c002" => 3 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
        { key: "C", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
      ])
    end

    it "skips a range string whose first bound is empty and returns unfiltered results" do
      params[:search_query] = {"chart-5445a001" => { "filters" => ["-200"] }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a002"}[:data]

      expect(chart_data).to match_array([
        { key: "A", "01973b63-7418-7b29-a136-c499e389c002" => 3 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
        { key: "C", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
      ])
    end

    it "skips a bare dash string and returns unfiltered results" do
      params[:search_query] = {"chart-5445a001" => { "filters" => ["-"] }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a002"}[:data]

      expect(chart_data).to match_array([
        { key: "A", "01973b63-7418-7b29-a136-c499e389c002" => 3 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
        { key: "C", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
      ])
    end

    it "applies only the valid range when one range is malformed and one is valid" do
      params[:search_query] = {"chart-5445a001" => { "filters" => ["0-", "400-600"] }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a002"}[:data]

      expect(chart_data).to match_array([
        { key: "C", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
      ])
    end

    it "applies a terms filter (not a range filter) when the agg is not 'range'" do
      params[:search_query] = {"chart-5445a002" => { "filters" => ["A"] }}
      price_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a001"}&.dig(:data)

      expect(price_data).to match_array([
        {key: "0.0-200.0", "01973b63-7418-7b29-a136-c499e389c001"=>2},
        {key: "200.0-400.0", "01973b63-7418-7b29-a136-c499e389c001"=>1},
        {key: "400.0-600.0", "01973b63-7418-7b29-a136-c499e389c001"=>0},
      ])
    end

    it "excludes records whose price falls in the excluded range bucket" do
      params[:search_query] = {"chart-5445a001" => { "exclusion_filters" => ["0-200"] }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a002"}[:data]

      expect(chart_data).to match_array([
        { key: "A", "01973b63-7418-7b29-a136-c499e389c002" => 1 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
        { key: "C", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
      ])
    end

    it "excludes records matching any of multiple excluded range buckets" do
      params[:search_query] = {"chart-5445a001" => { "exclusion_filters" => ["0-200", "200-400"] }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a002"}[:data]

      expect(chart_data).to match_array([
        { key: "C", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
      ])
    end

    it "skips malformed exclusion range and returns unfiltered results" do
      params[:search_query] = {"chart-5445a001" => { "exclusion_filters" => ["0-"] }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a002"}[:data]

      expect(chart_data).to match_array([
        { key: "A", "01973b63-7418-7b29-a136-c499e389c002" => 3 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
        { key: "C", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
      ])
    end

    it "skips a bare dash string on exclusion range and returns unfiltered results" do
      params[:search_query] = {"chart-5445a001" => { "filters" => ["-"] }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a002"}[:data]

      expect(chart_data).to match_array([
        { key: "A", "01973b63-7418-7b29-a136-c499e389c002" => 3 },
        { key: "B", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
        { key: "C", "01973b63-7418-7b29-a136-c499e389c002" => 2 },
      ])
    end

    it "sorts range buckets by doc_count ascending" do
      params[:search_query] = {"chart-5445b001" => { "order" => { "y" => "asc" } }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a001"}[:data]

      expect(chart_data).to match_array([
        {"01973b63-7418-7b29-a136-c499e389c001"=>2, :key=>"0.0-200.0"},
        {"01973b63-7418-7b29-a136-c499e389c001"=>2, :key=>"400.0-600.0"},
        {"01973b63-7418-7b29-a136-c499e389c001"=>3, :key=>"200.0-400.0"},
      ])
    end

    it "sorts range buckets by doc_count descending" do
      params[:search_query] = {"chart-5445b001" => { "order" => { "y" => "desc" } }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a001"}[:data]

      expect(chart_data).to match_array([
        {"01973b63-7418-7b29-a136-c499e389c001"=>3, :key=>"200.0-400.0"},
        {"01973b63-7418-7b29-a136-c499e389c001"=>2, :key=>"400.0-600.0"},
        {"01973b63-7418-7b29-a136-c499e389c001"=>2, :key=>"0.0-200.0"},
      ])

    end

    it "sorts range buckets by key ascending" do
      params[:search_query] = {"chart-5445b001" => { "order" => { "x" => "asc" } }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a001" }[:data]

      expect(chart_data).to match_array([
        {"01973b63-7418-7b29-a136-c499e389c001"=>2, :key=>"0.0-200.0"},
        {"01973b63-7418-7b29-a136-c499e389c001"=>2, :key=>"400.0-600.0"},
        {"01973b63-7418-7b29-a136-c499e389c001"=>3, :key=>"200.0-400.0"},
      ])
    end

    it "sorts range buckets by key ascending" do
      params[:search_query] = {"chart-5445b001" => { "order" => { "x": 'desc', "y": 'desc'} }}
      chart_data = adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445a001" }[:data]

      expect(chart_data).to match_array([
        {"01973b63-7418-7b29-a136-c499e389c001"=>3, :key=>"200.0-400.0"},
        {"01973b63-7418-7b29-a136-c499e389c001"=>2, :key=>"0.0-200.0"},
        {"01973b63-7418-7b29-a136-c499e389c001"=>2, :key=>"400.0-600.0"},
      ])
    end
  end

  context "z groups" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'category', type: 'String' },
          { name: 'gender',   type: 'String' },
          { name: 'price',    type: 'Integer' },
          { name: 'quantity', type: 'Integer' },
        ]
      )
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create!(category: 'A', gender: 'M', price: 10, quantity: 5)
        klass.const.create!(category: 'A', gender: 'M', price: 8,  quantity: 7)
        klass.const.create!(category: 'A', gender: 'F', price: 6,  quantity: 8)
        klass.const.create!(category: 'B', gender: 'M', price: 10, quantity: 15)
        klass.const.create!(category: 'B', gender: 'M', price: 10, quantity: 12)
        klass.const.create!(category: 'C', gender: 'F', price: 6,  quantity: 1)
        klass.const.create!(category: 'C', gender: 'F', price: 18, quantity: 2)
        klass.const.create!(category: 'C', gender: 'F', price: 20, quantity: 4)
        klass.const.create!(category: 'C', gender: 'M', price: 6,  quantity: 1)
        klass.const.create!(category: 'C', gender: 'M', price: 18, quantity: 2)
        klass.const.create!(category: 'C', gender: 'M', price: 20, quantity: 4)
      end
    end

    context "terms x, z only (no y)" do
      let(:x_id) { "01973b63-7418-7b29-a136-c499e389d091" }
      let(:z_id) { "01973b63-7418-7b29-a136-c499e389d092" }

      let(:data_A) {{ key: "A", x_id => 3, "M" => 2, "F" => 1 }}
      let(:data_B) {{ key: "B", x_id => 2, "M" => 2 }}
      let(:data_C) {{ key: "C", x_id => 6, "M" => 3, "F" => 3 }}

      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc80",
        }.with_indifferent_access
      end

      before(:each) do
        D::Client::R::Dashboard.create!(
          id: "01973af8-69c0-711d-8976-4cec959dcc80",
          name: 'dashboard',
          charts_attributes: [{
            id: "01973b53-b8c0-7207-9be1-caef5445cc10",
            type: "Bar",
            groups_attributes: [
              { id: x_id, source: "attr", attr: "category", agg: "terms", value_type: "string", axis: "x", position: 0, size: 10 },
              { id: z_id, source: "attr", attr: "gender",   agg: "terms", value_type: "string", axis: "z", position: 1, size: 10 },
            ]
          }]
        )
      end

      def chart_data
        adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445cc10" }
      end

      it "returns z_keys, empty y_group_ids and data" do
        result = chart_data
        expect(result[:z_keys]).to match_array(['M', 'F'])
        expect(result[:y_group_ids]).to eq([])
        expect(result[:data]).to match_array([data_A, data_B, data_C])
      end

      it "x asc" do
        params[:search_query] = { "chart-5445cc10" => { 'order' => { 'x' => 'asc', 'y' => nil } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["A", "B", "C"])
      end

      it "x desc" do
        params[:search_query] = { "chart-5445cc10" => { 'order' => { 'x' => 'desc', 'y' => nil } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["C", "B", "A"])
      end

      it "y asc" do
        params[:search_query] = { "chart-5445cc10" => { 'order' => { 'x' => nil, 'y' => 'asc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["B", "A", "C"])
      end

      it "y desc" do
        params[:search_query] = { "chart-5445cc10" => { 'order' => { 'x' => nil, 'y' => 'desc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["C", "A", "B"])
      end
    end

    context "terms x, single y, z" do
      let(:x_id)  { "01973b63-7418-7b29-a136-c499e389d101" }
      let(:z_id)  { "01973b63-7418-7b29-a136-c499e389d102" }
      let(:y1_id) { "01973b63-7418-7b29-a136-c499e389d103" }

      let(:data_A) {{ key: "A", x_id => 3, "M__#{y1_id}" => 18.0, "F__#{y1_id}" => 6.0 }}
      let(:data_B) {{ key: "B", x_id => 2, "M__#{y1_id}" => 20.0 }}
      let(:data_C) {{ key: "C", x_id => 6, "M__#{y1_id}" => 44.0, "F__#{y1_id}" => 44.0 }}

      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc81",
        }.with_indifferent_access
      end

      before(:each) do
        D::Client::R::Dashboard.create!(
          id: "01973af8-69c0-711d-8976-4cec959dcc81",
          name: 'dashboard',
          charts_attributes: [{
            id: "01973b53-b8c0-7207-9be1-caef5445cc11",
            type: "Bar",
            groups_attributes: [
              { id: x_id,  source: "attr", attr: "category", agg: "terms", value_type: "string", axis: "x", position: 0, size: 10 },
              { id: z_id,  source: "attr", attr: "gender",   agg: "terms", value_type: "string", axis: "z", position: 1, size: 10 },
              { id: y1_id, source: "attr", attr: "price",    agg: "sum",   value_type: "number", axis: "y", position: 2 },
            ]
          }]
        )
      end

      def chart_data
        adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445cc11" }
      end

      it "returns z_keys, y_group_ids and data" do
        result = chart_data
        expect(result[:z_keys]).to match_array(['M', 'F'])
        expect(result[:y_group_ids]).to eq([y1_id])
        expect(result[:data]).to match_array([data_A, data_B, data_C])
      end

      it "x asc" do
        params[:search_query] = { "chart-5445cc11" => { 'order' => { 'x' => 'asc', 'y' => nil } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["A", "B", "C"])
      end

      it "x desc" do
        params[:search_query] = { "chart-5445cc11" => { 'order' => { 'x' => 'desc', 'y' => nil } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["C", "B", "A"])
      end

      it "y asc" do
        params[:search_query] = { "chart-5445cc11" => { 'order' => { 'x' => nil, 'y' => 'asc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["B", "A", "C"])
      end

      it "y desc" do
        params[:search_query] = { "chart-5445cc11" => { 'order' => { 'x' => nil, 'y' => 'desc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["C", "A", "B"])
      end
    end

    context "terms x, multiple y, z" do
      let(:x_id)  { "01973b63-7418-7b29-a136-c499e389d111" }
      let(:z_id)  { "01973b63-7418-7b29-a136-c499e389d112" }
      let(:y1_id) { "01973b63-7418-7b29-a136-c499e389d113" }
      let(:y2_id) { "01973b63-7418-7b29-a136-c499e389d114" }

      let(:data_A) {{ key: "A", x_id => 3, "M__#{y1_id}" => 18.0, "F__#{y1_id}" => 6.0, "M__#{y2_id}" => 12.0, "F__#{y2_id}" => 8.0 }}
      let(:data_B) {{ key: "B", x_id => 2, "M__#{y1_id}" => 20.0, "M__#{y2_id}" => 27.0 }}
      let(:data_C) {{ key: "C", x_id => 6, "M__#{y1_id}" => 44.0, "F__#{y1_id}" => 44.0, "M__#{y2_id}" => 7.0, "F__#{y2_id}" => 7.0 }}

      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc82",
        }.with_indifferent_access
      end

      before(:each) do
        D::Client::R::Dashboard.create!(
          id: "01973af8-69c0-711d-8976-4cec959dcc82",
          name: 'dashboard',
          charts_attributes: [{
            id: "01973b53-b8c0-7207-9be1-caef5445cc12",
            type: "Bar",
            groups_attributes: [
              { id: x_id,  source: "attr", attr: "category", agg: "terms", value_type: "string", axis: "x", position: 0, size: 10 },
              { id: z_id,  source: "attr", attr: "gender",   agg: "terms", value_type: "string", axis: "z", position: 1, size: 10 },
              { id: y1_id, source: "attr", attr: "price",    agg: "sum",   value_type: "number", axis: "y", position: 2 },
              { id: y2_id, source: "attr", attr: "quantity", agg: "sum",   value_type: "number", axis: "y", position: 3 },
            ]
          }]
        )
      end

      def chart_data
        adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445cc12" }
      end

      it "returns z_keys, both y_group_ids and data" do
        result = chart_data
        expect(result[:z_keys]).to match_array(['M', 'F'])
        expect(result[:y_group_ids]).to eq([y1_id, y2_id])
        expect(result[:data]).to match_array([data_A, data_B, data_C])
      end

      it "both y values appear per z key in data" do
        row_A = chart_data[:data].find { |r| r[:key] == "A" }
        expect(row_A).to include("M__#{y1_id}" => 18.0, "F__#{y1_id}" => 6.0, "M__#{y2_id}" => 12.0, "F__#{y2_id}" => 8.0)
      end

      it "x asc" do
        params[:search_query] = { "chart-5445cc12" => { 'order' => { 'x' => 'asc', 'y' => nil } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["A", "B", "C"])
      end

      it "x desc" do
        params[:search_query] = { "chart-5445cc12" => { 'order' => { 'x' => 'desc', 'y' => nil } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["C", "B", "A"])
      end

      it "y asc" do
        params[:search_query] = { "chart-5445cc12" => { 'order' => { 'x' => nil, 'y' => 'asc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["B", "A", "C"])
      end

      it "y desc" do
        params[:search_query] = { "chart-5445cc12" => { 'order' => { 'x' => nil, 'y' => 'desc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["C", "A", "B"])
      end
    end

    context "range x, z only (no y)" do
      let(:x_id) { "01973b63-7418-7b29-a136-c499e389d071" }
      let(:z_id) { "01973b63-7418-7b29-a136-c499e389d072" }


      let(:data_A) {{ key: "0.0-10.0",  x_id => 9, "M" => 5, "F" => 4 }}
      let(:data_B) {{ key: "10.0-20.0", x_id => 2, "M" => 2 }}
      let(:data_C) {{ key: "20.0-30.0", x_id => 0 }}

      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc78"
        }.with_indifferent_access
      end

      before(:each) do
        D::Client::R::Dashboard.create!(
          id: "01973af8-69c0-711d-8976-4cec959dcc78",
          name: 'dashboard',
          charts_attributes: [{
            id: "01973b53-b8c0-7207-9be1-caef5445cc08",
            type: "Bar",
            groups_attributes: [
              { id: x_id, source: "attr", attr: "quantity", agg: "range", value_type: "number", axis: "x", position: 0,
                ranges_attributes: [{ from: 0, to: 10 }, { from: 10, to: 20 }, { from: 20, to: 30 }] },
              { id: z_id, source: "attr", attr: "gender",   agg: "terms", value_type: "string",  axis: "z", position: 1, size: 10 },
            ]
          }]
        )
      end

      def chart_data
        adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445cc08" }
      end

      it "without sort: returns z_keys, empty y_group_ids and range-keyed data" do
        result = chart_data
        expect(result[:z_keys]).to match_array(['M', 'F'])
        expect(result[:y_group_ids]).to eq([])
        expect(result[:data]).to match_array([data_A, data_B, data_C])
      end

      it "x asc" do
        params[:search_query] = { "chart-5445cc08" => { 'order' => { 'x' => 'asc', 'y' => nil } } }
        expect(chart_data[:data]).to eq([data_A, data_B, data_C])
      end

      it "x desc" do
        params[:search_query] = { "chart-5445cc08" => { 'order' => { 'x' => 'desc', 'y' => nil } } }
        expect(chart_data[:data]).to eq([data_C, data_B, data_A])
      end

      it "y asc (sorts by doc_count since no y group)" do
        params[:search_query] = { "chart-5445cc08" => { 'order' => { 'x' => nil, 'y' => 'asc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["20.0-30.0", "10.0-20.0", "0.0-10.0"])
      end

      it "y desc (sorts by doc_count since no y group)" do
        params[:search_query] = { "chart-5445cc08" => { 'order' => { 'x' => nil, 'y' => 'desc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["0.0-10.0", "10.0-20.0", "20.0-30.0"])
      end
    end

    context "range x, single y, z" do
      let(:x_id)  { "01973b63-7418-7b29-a136-c499e389d061" }
      let(:z_id)  { "01973b63-7418-7b29-a136-c499e389d062" }
      let(:y1_id) { "01973b63-7418-7b29-a136-c499e389d063" }

      let(:data_A) {{ key: "0.0-10.0",  x_id => 9, "M__#{y1_id}" => 62.0, "F__#{y1_id}" => 50.0 }}
      let(:data_B) {{ key: "10.0-20.0", x_id => 2, "M__#{y1_id}" => 20.0 }}
      let(:data_C) {{ key: "20.0-30.0", x_id => 0 }}

      let(:params) do
        { "schema_name" => "Client", "klass_name" => "Klass",
          "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc77" }.with_indifferent_access
      end

      before(:each) do
        D::Client::R::Dashboard.create!(
          id: "01973af8-69c0-711d-8976-4cec959dcc77",
          name: 'dashboard',
          charts_attributes: [{
            id: "01973b53-b8c0-7207-9be1-caef5445cc07",
            type: "Bar",
            groups_attributes: [
              { id: x_id,  source: "attr", attr: "quantity", agg: "range", value_type: "number", axis: "x", position: 0,
                ranges_attributes: [{ from: 0, to: 10 }, { from: 10, to: 20 }, { from: 20, to: 30 }] },
              { id: z_id,  source: "attr", attr: "gender",   agg: "terms", value_type: "string",  axis: "z", position: 1, size: 10 },
              { id: y1_id, source: "attr", attr: "price",    agg: "sum",   value_type: "number",  axis: "y", position: 2 },
            ]
          }]
        )
      end

      def chart_data
        adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445cc07" }
      end

      it "without sort: returns z_keys, y_group_ids and range-keyed data" do
        result = chart_data
        expect(result[:z_keys]).to match_array(['M', 'F'])
        expect(result[:y_group_ids]).to eq([y1_id])
        expect(result[:data]).to match_array([data_A, data_B, data_C])
      end

      it "x asc" do
        params[:search_query] = { "chart-5445cc07" => { 'order' => { 'x' => 'asc', 'y' => nil } } }
        expect(chart_data[:data]).to eq([data_A, data_B, data_C])
      end

      it "x desc" do
        params[:search_query] = { "chart-5445cc07" => { 'order' => { 'x' => 'desc', 'y' => nil } } }
        expect(chart_data[:data]).to eq([data_C, data_B, data_A])
      end

      it "y asc" do
        params[:search_query] = { "chart-5445cc07" => { 'order' => { 'x' => nil, 'y' => 'asc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["20.0-30.0", "10.0-20.0", "0.0-10.0"])
      end

      it "y desc" do
        params[:search_query] = { "chart-5445cc07" => { 'order' => { 'x' => nil, 'y' => 'desc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["0.0-10.0", "10.0-20.0", "20.0-30.0"])
      end
    end

    context "range x, multiple y, z" do
      let(:x_id)  { "01973b63-7418-7b29-a136-c499e389d081" }
      let(:z_id)  { "01973b63-7418-7b29-a136-c499e389d082" }
      let(:y1_id) { "01973b63-7418-7b29-a136-c499e389d083" }
      let(:y2_id) { "01973b63-7418-7b29-a136-c499e389d084" }

      let(:data_A) {{ key: "0.0-10.0",  x_id => 9, "M__#{y1_id}" => 62.0, "F__#{y1_id}" => 50.0, "M__#{y2_id}" => 19.0, "F__#{y2_id}" => 15.0 }}
      let(:data_B) {{ key: "10.0-20.0", x_id => 2, "M__#{y1_id}" => 20.0, "M__#{y2_id}" => 27.0 }}
      let(:data_C) {{ key: "20.0-30.0", x_id => 0 }}

      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc79",
        }.with_indifferent_access
      end

      before(:each) do
        D::Client::R::Dashboard.create!(
          id: "01973af8-69c0-711d-8976-4cec959dcc79",
          name: 'dashboard',
          charts_attributes: [{
            id: "01973b53-b8c0-7207-9be1-caef5445cc09",
            type: "Bar",
            groups_attributes: [
              { id: x_id,  source: "attr", attr: "quantity", agg: "range", value_type: "number", axis: "x", position: 0,
                ranges_attributes: [{ from: 0, to: 10 }, { from: 10, to: 20 }, { from: 20, to: 30 }] },
              { id: z_id,  source: "attr", attr: "gender",   agg: "terms", value_type: "string",  axis: "z", position: 1, size: 10 },
              { id: y1_id, source: "attr", attr: "price",    agg: "sum",   value_type: "number",  axis: "y", position: 2 },
              { id: y2_id, source: "attr", attr: "quantity", agg: "sum",   value_type: "number",  axis: "y", position: 3 },
            ]
          }]
        )
      end

      def chart_data
        adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445cc09" }
      end

      it "without sort: returns z_keys, both y_group_ids and range-keyed data" do
        result = chart_data
        expect(result[:z_keys]).to match_array(['M', 'F'])
        expect(result[:y_group_ids]).to eq([y1_id, y2_id])
        expect(result[:data]).to match_array([data_A, data_B, data_C])
      end

      it "x asc" do
        params[:search_query] = { "chart-5445cc09" => { 'order' => { 'x' => 'asc', 'y' => nil } } }
        expect(chart_data[:data]).to eq([data_A, data_B, data_C])
      end

      it "x desc" do
        params[:search_query] = { "chart-5445cc09" => { 'order' => { 'x' => 'desc', 'y' => nil } } }
        expect(chart_data[:data]).to eq([data_C, data_B, data_A])
      end

      it "y asc" do
        params[:search_query] = { "chart-5445cc09" => { 'order' => { 'x' => nil, 'y' => 'asc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["20.0-30.0", "10.0-20.0", "0.0-10.0"])
      end

      it "y desc" do
        params[:search_query] = { "chart-5445cc09" => { 'order' => { 'x' => nil, 'y' => 'desc' } } }
        expect(chart_data[:data].map { |r| r[:key] }).to eq(["0.0-10.0", "10.0-20.0", "20.0-30.0"])
      end
    end
  end

  context "z group size limit" do
    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'region',  type: 'String' },
          { name: 'segment', type: 'String' },
        ]
      )
    end

    let(:x_id) { "01973b63-7418-7b29-a136-c499e389d201" }
    let(:z_id) { "01973b63-7418-7b29-a136-c499e389d202" }

    let(:params) do
      { "schema_name" => "Client", "klass_name" => "Klass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc90" }.with_indifferent_access
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        5.times { klass.const.create!(region: 'North', segment: 'A') }
        4.times { klass.const.create!(region: 'North', segment: 'B') }
        3.times { klass.const.create!(region: 'North', segment: 'C') }
        2.times { klass.const.create!(region: 'North', segment: 'D') }
        1.times { klass.const.create!(region: 'North', segment: 'E') }
        1.times { klass.const.create!(region: 'North', segment: 'F') }
      end

      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc90",
        name: 'dashboard',
        charts_attributes: [{
          id: "01973b53-b8c0-7207-9be1-caef5445cc20",
          type: "Bar",
          groups_attributes: [
            { id: x_id, source: "attr", attr: "region",  agg: "terms", value_type: "string", axis: "x", position: 0, size: 10 },
            { id: z_id, source: "attr", attr: "segment", agg: "terms", value_type: "string", axis: "z", position: 1, size: 4 },
          ]
        }]
      )
    end

    def chart_data
      adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445cc20" }
    end

    it "z_keys contains only top 4 segments even though 6 distinct values exist" do
      result = chart_data
      expect(result[:z_keys]).to match_array(['A', 'B', 'C', 'D'])
      expect(result[:z_keys]).not_to include('E', 'F')
    end

    it "data row contains only z keys within the size limit" do
      north_row = chart_data[:data].find { |r| r[:key] == 'North' }
      expect(north_row.keys).to include('A', 'B', 'C', 'D')
      expect(north_row.keys).not_to include('E', 'F')
    end

    it "data counts match top 4 segments" do
      north_row = chart_data[:data].find { |r| r[:key] == 'North' }
      expect(north_row).to include('A' => 5, 'B' => 4, 'C' => 3, 'D' => 2)
    end
  end

  context "chart_search_filter (contains keyword search)" do
    let(:dashboard_id) { "01973af8-69c0-711d-8976-4cec959dcc91" }

    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [{ name: 'job', type: 'String' }]
      )
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create(job: 'Directeur commercial')
        klass.const.create(job: 'Directeur technique')
        klass.const.create(job: 'Manager')
      end
      D::Client::R::Dashboard.create!(
        id: dashboard_id,
        name: 'dashboard',
        charts_attributes: [{
          id: "01973b53-b8c0-7207-9be1-caef5445cc08",
          type: "Bar",
          groups_attributes: [{
            id: "01973b53-b8c0-7207-9be1-caef55767639",
            source: "attr",
            attr: "job",
            agg: "terms",
            value_type: "string",
            axis: "x",
            position: 0,
          }]
        }]
      )
    end

    let(:chart_data) { adapter.as_json[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445cc08" } }

    context "when contains is absent" do
      let(:params) do
        { "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => dashboard_id
        }.with_indifferent_access
      end

      it "returns all records" do
        expect(chart_data[:data]).to match_array([
          { key: "Directeur commercial", "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
          { key: "Directeur technique",  "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
          { key: "Manager",              "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
        ])
      end
    end

    context "when contains is empty string" do
      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => dashboard_id,
          "search_query" => { "chart-#{"01973b53-b8c0-7207-9be1-caef5445cc08"[-8..-1]}" => { "contains" => "" } }
        }.with_indifferent_access
      end

      it "returns all records (no filter applied)" do
        expect(chart_data[:data]).to match_array([
          { key: "Directeur commercial", "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
          { key: "Directeur technique",  "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
          { key: "Manager",              "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
        ])
      end
    end

    context "when contains matches multiple records" do
      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => dashboard_id,
          "search_query" => { "chart-#{"01973b53-b8c0-7207-9be1-caef5445cc08"[-8..-1]}" => { "contains" => "directeur" } }
        }.with_indifferent_access
      end

      it "returns only records matching the term" do
        expect(chart_data[:data]).to match_array([
          { key: "Directeur commercial", "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
          { key: "Directeur technique",  "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
        ])
      end
    end

    context "when contains is uppercase (case-insensitive)" do
      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => dashboard_id,
          "search_query" => { "chart-#{"01973b53-b8c0-7207-9be1-caef5445cc08"[-8..-1]}" => { "contains" => "DIRECTEUR" } }
        }.with_indifferent_access
      end

      it "returns matching records regardless of case" do
        expect(chart_data[:data]).to match_array([
          { key: "Directeur commercial", "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
          { key: "Directeur technique",  "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
        ])
      end
    end

    context "when contains matches exactly one record" do
      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => dashboard_id,
          "search_query" => { "chart-#{"01973b53-b8c0-7207-9be1-caef5445cc08"[-8..-1]}" => { "contains" => "commercial" } }
        }.with_indifferent_access
      end

      it "returns only that record" do
        expect(chart_data[:data]).to match_array([
          { key: "Directeur commercial", "01973b53-b8c0-7207-9be1-caef55767639" => 1 },
        ])
      end
    end

    context "when contains matches nothing" do
      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => dashboard_id,
          "search_query" => { "chart-#{"01973b53-b8c0-7207-9be1-caef5445cc08"[-8..-1]}" => { "contains" => "xyz_no_match" } }
        }.with_indifferent_access
      end

      it "returns empty data" do
        expect(chart_data[:data]).to be_empty
      end
    end
  end

  context "chart_search_filter (contains search on number and date value types)" do
    let(:dashboard_id) { "01973af8-69c0-711d-8976-4cec959dcc93" }

    let(:klass) do
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'age', type: 'Integer' },
          { name: 'hired_at', type: 'Date' },
        ]
      )
    end

    before(:each) do
      Dynamic::Elasticsearch.wait_for_complete do
        klass.const.create(age: 25, hired_at: Date.parse('2020-01-15'))
        klass.const.create(age: 25, hired_at: Date.parse('2021-03-10'))
        klass.const.create(age: 32, hired_at: Date.parse('2020-01-15'))
      end
      D::Client::R::Dashboard.create!(
        id: dashboard_id,
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445cc13",
            type: "Bar",
            groups_attributes: [{
              id: "01973b53-b8c0-7207-9be1-caef55767642",
              source: "attr",
              attr: "age",
              agg: "terms",
              value_type: "number",
              axis: "x",
              position: 0,
            }]
          },
          {
            id: "01973b53-b8c0-7207-9be1-caef5445cc14",
            type: "Bar",
            groups_attributes: [{
              id: "01973b53-b8c0-7207-9be1-caef55767643",
              source: "attr",
              attr: "hired_at",
              agg: "terms",
              value_type: "date",
              axis: "x",
              position: 0,
            }]
          }
        ]
      )
    end

    let(:age_chart_data) { adapter.as_json[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445cc13" } }
    let(:date_chart_data) { adapter.as_json[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445cc14" } }

    context "when contains is the exact integer value" do
      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => dashboard_id,
          "search_query" => { "chart-#{"01973b53-b8c0-7207-9be1-caef5445cc13"[-8..-1]}" => { "contains" => "25" } }
        }.with_indifferent_access
      end

      it "returns only records whose value equals the number exactly" do
        expect(age_chart_data[:data]).to match_array([
          { key: 25, "01973b53-b8c0-7207-9be1-caef55767642" => 2 },
        ])
      end
    end

    context "when contains is a digit substring of an integer, not the whole value" do
      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => dashboard_id,
          "search_query" => { "chart-#{"01973b53-b8c0-7207-9be1-caef5445cc13"[-8..-1]}" => { "contains" => "2" } }
        }.with_indifferent_access
      end

      it "does not match, since number search requires an exact value rather than a substring" do
        expect(age_chart_data[:data]).to be_empty
      end
    end

    context "when contains is the exact date value" do
      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => dashboard_id,
          "search_query" => { "chart-#{"01973b53-b8c0-7207-9be1-caef5445cc14"[-8..-1]}" => { "contains" => "2020-01-15" } }
        }.with_indifferent_access
      end

      it "returns only records matching that exact date" do
        expect(date_chart_data[:data]).to match_array([
          { key: 1579046400000, "01973b53-b8c0-7207-9be1-caef55767643" => 2 },
        ])
      end
    end

    context "when contains does not match any date" do
      let(:params) do
        {
          "schema_name" => "Client",
          "klass_name" => "Klass",
          "dashboard_id" => dashboard_id,
          "search_query" => { "chart-#{"01973b53-b8c0-7207-9be1-caef5445cc14"[-8..-1]}" => { "contains" => "1999-12-31" } }
        }.with_indifferent_access
      end

      it "returns empty data" do
        expect(date_chart_data[:data]).to be_empty
      end
    end
  end

  context "subclass with one attribute" do
    let(:build_schema){ [klass, subklass] }
    let(:klass) {
      schema.klasses.create(
        name: 'Klass',
        attrs_attributes: [
          { name: 'inherited_attr', type: 'String' }
        ]
      )
    }

    let(:subklass){
      schema.klasses.create(
        name: 'SubKlass',
        superklass: klass,
        attrs_attributes: [
          { name: 'own_attr', type: 'String' }
        ]
      )
    }

    let(:params) do
      {
        "schema_name" => "Client",
        "klass_name" => "SubKlass",
        "dashboard_id" => "01973af8-69c0-711d-8976-4cec959dcc13",
      }.with_indifferent_access
    end

    let(:adapter) { Dynamic::Dashboard::Adapter.new(subklass.const, params) }

    before(:each) do
      schema.load
      klass.update_elasticsearch_index(true)

      Dynamic::Elasticsearch.wait_for_complete do
        subklass.const.create(inherited_attr: 'val 1', own_attr: 'own 1')
        subklass.const.create(inherited_attr: 'val 1', own_attr: 'own 1')
        subklass.const.create(inherited_attr: 'val 2', own_attr: 'own 2')
      end

      D::Client::R::Dashboard.create!(
        id: "01973af8-69c0-711d-8976-4cec959dcc13",
        name: 'dashboard',
        charts_attributes: [
          {
            id: "01973b53-b8c0-7207-9be1-caef5445beac",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7418-7b29-a136-c499e389c568",
                source: "attr",
                attr: "own_attr",
                agg: "terms",
                value_type: "string"
              }
            ]
          },
          {
            id: "01973b53-bca8-71a8-8799-c6119ae76058",
            type: "Pie",
            groups_attributes: [
              {
                id: "01973b63-7be8-7a83-9d54-34e07208a9ea",
                source: "attr",
                attr: "inherited_attr",
                agg: "terms",
                value_type: "string"
              }
            ]
          }
        ]
      )
    end

    it "should return aggregation on the subclass's own attribute" do
      expect(
        adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-b8c0-7207-9be1-caef5445beac" }.try(:[], :data)
      ).to match_array([
        {key: "own 1", "01973b63-7418-7b29-a136-c499e389c568" => 2},
        {key: "own 2", "01973b63-7418-7b29-a136-c499e389c568" => 1}
      ])
    end

    it "should return aggregation on an attribute inherited from the parent klass" do
      expect(
        adapter.as_json()[:charts].detect { |c| c[:uuid] == "01973b53-bca8-71a8-8799-c6119ae76058" }.try(:[], :data)
      ).to match_array([
        {key: "val 1", "01973b63-7be8-7a83-9d54-34e07208a9ea" => 2},
        {key: "val 2", "01973b63-7be8-7a83-9d54-34e07208a9ea" => 1}
      ])
    end
  end

end
