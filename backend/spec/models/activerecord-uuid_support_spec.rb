describe ActiveRecord::UuidSupport, elasticsearch: false, sidekiq: false do

  it 'table primary_keys should be uuid by default and using uuid_generate_v7' do
    expect(ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition < ActiveRecord::UuidSupport::ConnectionAdapters::PostgreSQL::ColumnMethods).to be true
  end

end
