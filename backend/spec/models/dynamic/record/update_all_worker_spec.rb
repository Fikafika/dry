describe Dynamic::Record::UpdateAllWorker do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @klass = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])
    @schema.load

    Dynamic::Elasticsearch.wait_for_complete(timeout: 20) do
      @a1 = D::My::Contact.create!(name: 'A 1')
      @a2 = D::My::Contact.create!(name: 'A 2')
      @b = D::My::Contact.create!(name: 'B')
    end

    @user = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
  end

  it 'should update all' do
    perform_params = {
      user_id: @user.id,
      klass_name: 'D::My::Contact',
      params: {
        scopes: {'0' => {name: 'where_filters', args: {'0' => {name: {contains: 'A'}}}}},
        base: {name: 'A'},
      }
    }.deep_stringify_keys

    expect {
      Dynamic::Record::UpdateAllWorker.wait_for_complete do
        Dynamic::Record::UpdateAllWorker.perform_async(perform_params)
      end
    }.to change {
      @a1.reload.name
    }.from('A 1').to('A').and change {
      @a2.reload.name
    }.from('A 2').to('A')

    expect(@b.name).to eq 'B'
  end

  it 'should update notification progress' do
    notification = D::My::R::Notification.create!()
    perform_params = {
      user_id: @user.id,
      notification: notification,
      klass_name: 'D::My::Contact',
      params: {
        scopes: {'0' => {name: 'where_filters', args: {'0' => {name: {contains: 'A'}}}}},
        base: {name: 'A'},
      }
    }.deep_stringify_keys

    expect {
      Dynamic::Record::UpdateAllWorker.wait_for_complete do
        Dynamic::Record::UpdateAllWorker.perform_async(perform_params)
      end
      notification.reload
    }.to change {
      notification.total
    }.to(2).and change {
      notification.current
    }.to(2).and change {
      notification.state
    }.to('finished')
  end

  it 'should do nothing if no user provided' do
    perform_params = {
      params: {
        scopes: {'0' => {name: 'where_filters', args: {'0' => {name: {contains: 'A'}}}}},
        base: {name: 'A'},
      }
    }.deep_stringify_keys

    expect {
      Dynamic::Record::UpdateAllWorker.wait_for_complete do
        Dynamic::Record::UpdateAllWorker.perform_async(perform_params)
      end
    }.to_not change {
      @a1.reload.name
    }
  end

end
