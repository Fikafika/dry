describe Dynamic::DocumentManagement::RegularFile, elasticsearch: false, sidekiq: false do

  def build_blob(filename)
    ::ActiveStorage::Blob.create_and_upload!(io: ::StringIO.new, filename: filename)
  end

  before(:each) do
    @community = Community.create!(name: 'my', permalink: 'my')
    @schema = Dynamic::Schema.where(name: @community.name.classify).first
    @schema.features.where.not(name: "Dynamic::DocumentManagement::Feature").destroy_all
    @Contact = @schema.klasses.create!(name: 'Contact') # for authors
    @schema = @schema.class.find(@schema.id)

    @feature = @schema.features.detect{ |f| f.name == "Dynamic::DocumentManagement::Feature" }
    @feature.update(enabled: true)

    @schema.load
  end

  it 'save a with an asset should update its name' do
    filename = 'test.txt'
    f = D::My::RegularFile.create!(asset: build_blob(filename))
    expect(f.name).to eq filename
  end

  xit 'detach an asset should destroy document' # ?

end
