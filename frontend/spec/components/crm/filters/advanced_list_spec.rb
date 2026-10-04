describe 'Crm::Filters::AdvancedList', type: :system do

  describe 'each_row_with_key' do

    it 'yields keys derived from the column name, disambiguated by occurrence' do
      result = page_eval do
        column = lambda do |name|
          c = Object.new
          c.define_singleton_method(:name) { name }
          c
        end
        list = [
          ['and', column.call('first_name'), []],
          ['and', column.call('amount'), []],
          ['and', column.call('amount'), []],
          ['separator'],
        ]
        component = Crm::Filters::AdvancedList.allocate
        component.define_singleton_method(:list) { list }
        keys = []
        component.each_row_with_key{|column_filters, i, key| keys << key}
        keys.to_n
      end

      expect(result).to eq(['first_name-1', 'amount-1', 'amount-2', 'separator-1'])
    end

    it 'restarts the counters on each traversal' do
      result = page_eval do
        column = lambda do |name|
          c = Object.new
          c.define_singleton_method(:name) { name }
          c
        end
        list = [
          ['and', column.call('amount'), []],
          ['and', column.call('amount'), []],
        ]
        component = Crm::Filters::AdvancedList.allocate
        component.define_singleton_method(:list) { list }
        first = []
        component.each_row_with_key{|column_filters, i, key| first << key}
        second = []
        component.each_row_with_key{|column_filters, i, key| second << key}
        (first == second).to_n
      end

      expect(result).to be(true)
    end

  end

end
