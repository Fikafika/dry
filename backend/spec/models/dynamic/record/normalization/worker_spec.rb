describe Dynamic::Record::Normalization::Worker, elasticsearch: true, sidekiq: true do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @user = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')

    @klass = @schema.klasses.create!(name: 'Contact')
    @first_name_attr = @klass.attrs.create!(name: 'first_name', type: 'String')
    @last_name_attr = @klass.attrs.create!(name: 'last_name', type: 'String')
    @schema.load

    Dynamic::Elasticsearch.wait_for_complete do
      @contact = D::My::Contact.create!(first_name: 'alain', last_name: 'soap')
    end

    @first_name_attr.normalizations.create!(type: 'CapitalizeFirstWord')
    @last_name_attr.normalizations.create!(type: 'CapitalizeFirstWord')
    @schema.load
  end

  context 'on all attributes' do

    it 'should normalize all values' do
      expect{
        Dynamic::Record::Normalization::Worker.wait_for_complete do
          @klass.normalize_all_records_asynchronously
        end
      }.to change {
        @contact.reload
        [@contact.first_name, @contact.last_name]
      }.from(['alain', 'soap']).to(['Alain', 'Soap'])
    end

  end

  context 'on a single attribute' do

    it 'should normalize values of corresponding attribute' do
      expect{
        Dynamic::Record::Normalization::Worker.wait_for_complete do
          @first_name_attr.normalize_all_records_asynchronously
        end
      }.to change {
        @contact.reload
        [@contact.first_name, @contact.last_name]
      }.from(['alain', 'soap']).to(['Alain', 'soap'])
    end

    it 'should update opensearch indices' do
      expect{
        Dynamic::Elasticsearch.wait_for_complete do
          Dynamic::Record::Normalization::Worker.wait_for_complete do
            @first_name_attr.normalize_all_records_asynchronously
          end
        end
      }.to change {
        src = @contact.__opensearch__.source
        [src['first_name'], src['last_name']]
      }.from(['alain', 'soap']).to(['Alain', 'soap'])
    end

  end

end