describe Api::Dynamic::Record::BaseController, type: :controller, elasticsearch: false, sidekiq: false  do
  include ::Devise::Test::ControllerHelpers

  before(:each) do
    request.env['devise.mapping'] = Devise.mappings[:user]
    @user = ::User.create!(email: 'contact@kosmopolead.com', login: 'contact@kosmopolead.com', super_admin: true)
    sign_in(@user)
  end
  after(:each) do
    User.current = nil
  end

  describe 'import' do
    before(:each) do
      @schema = Dynamic::Schema.create!(
        name: 'My',
        klasses_attributes: [{
          id: "8993fd99-572b-4718-8827-a7ce78a4b70f",
          name: 'Contact',
          attrs_attributes: [{
            name: 'first_name',
            type: 'String',
          }, {
            name: 'last_name',
            type: 'String',
          }],
          associations_attributes: [{
            name: 'assoc',
            target_klass_id: "8993fd99-572b-4718-8827-a7ce78a4b70f",
            type: "BelongsTo",
          }],
        }]
      )
    end

    it 'create new records and update existing records' do
      @schema.load
      contact1 = D::My::Contact.create!(id: '507d97c7-8cf4-4e99-a0fb-71bceaa26a13', first_name: 'A', last_name: 'A')
      contact2 = D::My::Contact.create!(id: 'b5e42c26-c426-49ee-a450-0076eb9915fb', first_name: 'B', last_name: 'B')
      contact3 = D::My::Contact.create!(id: 'a8a38fbf-4ca1-42d2-b148-193a109652f5', first_name: 'C', last_name: 'C')

      expect {
        post(:import, params: {
          'schema_name' => 'my',
          'klass_name' => 'contacts',
          'bases' => [
            { id: 'e89d5394-6395-4683-877f-d5c84b0221de', first_name: 'd' }, # new
            { id: 'b5e42c26-c426-49ee-a450-0076eb9915fb', first_name: 'b' }, # changed
            { id: '507d97c7-8cf4-4e99-a0fb-71bceaa26a13', first_name: 'a' }, # changed
          ]
        })
        contact1.reload
        contact2.reload
        contact3.reload
      }.to change {
        D::My::Contact.count
      }.by(1).and change {
        contact1.first_name
      }.from('A').to('a').and change {
        contact2.first_name
      }.from('B').to('b').and not_change {
        contact3.first_name
      }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        "ids" => [
          "e89d5394-6395-4683-877f-d5c84b0221de",
          "b5e42c26-c426-49ee-a450-0076eb9915fb",
          "507d97c7-8cf4-4e99-a0fb-71bceaa26a13",
        ],
        "errors" => {},
      })
    end

    it 'create new records with belongs_to association' do
      @schema.load
      contact1 = D::My::Contact.create!(id: '507d97c7-8cf4-4e99-a0fb-71bceaa26a13', first_name: 'A', last_name: 'A')
      contact2 = D::My::Contact.create!(id: 'b5e42c26-c426-49ee-a450-0076eb9915fb', first_name: 'B', last_name: 'B')

      expect {
        post(:import, params: {
          'schema_name' => 'my',
          'klass_name' => 'contacts',
          'bases' => [
            { id: 'e89d5394-6395-4683-877f-d5c84b0221de', assoc_id: '507d97c7-8cf4-4e99-a0fb-71bceaa26a13' }, # new
            { id: 'b5e42c26-c426-49ee-a450-0076eb9915fb', assoc_id: '507d97c7-8cf4-4e99-a0fb-71bceaa26a13' }, # changed          ]
          ]
        })
        contact1.reload
        contact2.reload
      }.to change {
        D::My::Contact.count
      }.by(1)

      expect(D::My::Contact.find('e89d5394-6395-4683-877f-d5c84b0221de').assoc.id).to eq('507d97c7-8cf4-4e99-a0fb-71bceaa26a13')
      expect(D::My::Contact.find('b5e42c26-c426-49ee-a450-0076eb9915fb').assoc.id).to eq('507d97c7-8cf4-4e99-a0fb-71bceaa26a13')

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        "ids" => [
          "e89d5394-6395-4683-877f-d5c84b0221de",
          "b5e42c26-c426-49ee-a450-0076eb9915fb",
        ],
        "errors" => {},
      })
    end

    context 'with validations' do
      before(:each) do
        @Contact = @schema.klasses.where(name: 'Contact').first
        @last_name_attr = @Contact.attrs.where(name: 'last_name').first
        @Contact.validations.create!(name: 'presence of last_name', attr: @last_name_attr, type: 'Presence')
      end

      it 'should return errors' do
        @schema.load
        contact1 = D::My::Contact.create!(id: '507d97c7-8cf4-4e99-a0fb-71bceaa26a13', first_name: 'A', last_name: 'A')
        contact2 = D::My::Contact.create!(id: 'b5e42c26-c426-49ee-a450-0076eb9915fb', first_name: 'B', last_name: 'B')
        contact3 = D::My::Contact.create!(id: 'a8a38fbf-4ca1-42d2-b148-193a109652f5', first_name: 'C', last_name: 'C')

        expect {
          post(:import, params: {
            'schema_name' => 'my',
            'klass_name' => 'contacts',
            'bases' => [
              { id: 'e89d5394-6395-4683-877f-d5c84b0221de', first_name: 'd', last_name: '' }, # new with error
              { id: 'b5e42c26-c426-49ee-a450-0076eb9915fb', first_name: 'b', last_name: '' }, # changed with error
              { id: '507d97c7-8cf4-4e99-a0fb-71bceaa26a13', first_name: 'a', last_name: 'A' }, # changed
            ]
          })
          contact1.reload
          contact2.reload
          contact3.reload
        }.to change {
          D::My::Contact.count
        }.by(0).and change {
          contact1.first_name
        }.from('A').to('a').and not_change {
          contact2.first_name
        }.and not_change {
          contact3.first_name
        }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({
          "ids" => [
            "507d97c7-8cf4-4e99-a0fb-71bceaa26a13",
          ],
          "errors" => {
            "0"=>{"last_name"=>[{"error"=>"blank"}]},
            "1"=>{"last_name"=>[{"error"=>"blank"}]},
          },
        })
      end
    end
  end

  describe 'update_positions' do
    before(:each) do
      @schema = Dynamic::Schema.create!(
        name: 'My',
        klasses_attributes: [{
          id: "8993fd99-572b-4718-8827-a7ce78a4b70f",
          name: 'Contact',
          attrs_attributes: [{
            name: 'first_name',
            type: 'String',
          }, {
            name: 'last_name',
            type: 'String',
          }, {
            name: 'position',
            type: 'Integer',
          }, {
            name: 'status',
            type: 'Enum',
            values_attributes: [{name: 'To do'}, {name: 'Current'}, {name: 'Finished'}]
          }],
        }]
      )
      @schema.load
      @contact1 = D::My::Contact.create!(first_name: 'A', last_name: 'A', status: 'To do')
      @contact2 = D::My::Contact.create!(first_name: 'B', last_name: 'B', status: 'To do')
      @contact3 = D::My::Contact.create!(first_name: 'C', last_name: 'C', status: 'To do')
      @contact4 = D::My::Contact.create!(first_name: 'D', last_name: 'D', status: 'To do')
      @contact5 = D::My::Contact.create!(first_name: 'E', last_name: 'E', status: 'Current')
      @contact6 = D::My::Contact.create!(first_name: 'F', last_name: 'F', status: 'Current')
      @contact7 = D::My::Contact.create!(first_name: 'G', last_name: 'G')
      @contact8 = D::My::Contact.create!(first_name: 'H', last_name: 'H')
      @contact9 = D::My::Contact.create!(first_name: 'I', last_name: 'I')

      def positions_for(context_value)
        position_klass = D::My::R::Position

        enum_value = D::My::Contact.statuses[context_value]

        positions = position_klass
          .where(context_attr: "status", context_value: enum_value)
          .order(value: :asc)

        positions.map do |position|
          [
            position.owner.first_name,
            position.value
          ]
        end
      end
    end

    context 'when moving inside the same column' do
      it 'moves a record before another record' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact1.id,#A
          target_id: @contact4.id,#D
          direction: 'before',
          attr: 'status',
          source: 'To do',
          target: 'To do',
        }
        expect(
          positions_for('To do')
        ).to eq([['B', 1], ['C', 2], ['A', 3], ['D', 4]])

        #Check that nothing changes
        expect(
          positions_for('Current')
        ).to be_empty
      end

      it 'moves a record after another record' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact1.id,#A
          target_id: @contact3.id,#C
          direction: 'after',
          attr: 'status',
          source: 'To do',
          target: 'To do',
        }
        expect(
          positions_for('To do')
        ).to eq([['B', 1], ['C', 2], ['A', 3], ['D', 4]])

        #Check that nothing changes
        expect(
          positions_for('Current')
        ).to be_empty
      end

      it 'moves the first record to the end' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact1.id,#A
          target_id: @contact4.id,#D
          direction: 'after',
          attr: 'status',
          source: 'To do',
          target: 'To do',
        }
        expect(
          positions_for('To do')
        ).to eq([['B', 1], ['C', 2], ['D', 3], ['A', 4]])
        expect(
          positions_for('Current')
        ).to be_empty
      end

      it 'moves the last record to the beginning' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact4.id,#D
          target_id: @contact1.id,#A
          direction: 'before',
          attr: 'status',
          source: 'To do',
          target: 'To do',
        }
        expect(
          positions_for('To do')
        ).to eq([['D', 1], ['A', 2], ['B', 3], ['C', 4]])
        expect(
          positions_for('Current')
        ).to be_empty
      end
    end

    context 'when moving between columns' do
      it 'moves a record before another record' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact1.id,#A
          target_id: @contact6.id,#F
          direction: 'before',
          attr: 'status',
          source: 'To do',
          target: 'Current',
        }
        expect(
          positions_for('To do')
        ).to eq([['B', 1], ['C', 2], ['D', 3]])
        expect(
          positions_for('Current')
        ).to eq([['E', 1], ['A', 2], ['F', 3]])
      end

      it 'moves a record after another record' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact1.id,#A
          target_id: @contact5.id,#E
          direction: 'after',
          attr: 'status',
          source: 'To do',
          target: 'Current',
        }
        expect(
          positions_for('To do')
        ).to eq([['B', 1], ['C', 2], ['D', 3]])
        expect(
          positions_for('Current')
        ).to eq([['E', 1], ['A', 2], ['F', 3]])
      end

      it 'moves to the end' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact1.id,#A
          target_id: @contact6.id,#F
          direction: 'after',
          attr: 'status',
          source: 'To do',
          target: 'Current',
        }
        expect(
          positions_for('To do')
        ).to eq([['B', 1], ['C', 2], ['D', 3]])
        expect(
          positions_for('Current')
        ).to eq([['E', 1], ['F', 2], ['A', 3]])
      end

      it 'moves to the beginning' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact1.id,#A
          target_id: @contact5.id,#E
          direction: 'before',
          attr: 'status',
          source: 'To do',
          target: 'Current',
        }
        expect(
          positions_for('To do')
        ).to eq([['B', 1], ['C', 2], ['D', 3]])
        expect(
          positions_for('Current')
        ).to eq([['A', 1], ['E', 2], ['F', 3]])
      end

      it 'moves from nil source' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact7.id,#G
          target_id: @contact6.id,#F
          direction: 'before',
          attr: 'status',
          source: nil,
          target: 'Current',
        }
        expect(
          positions_for(nil)
        ).to eq([['H', 1], ['I', 2]])
        expect(
          positions_for('Current')
        ).to eq([['E', 1], ['G', 2], ['F', 3]])
      end

      it 'moves to nil target' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact1.id,#A
          target_id: @contact8.id,#H
          direction: 'before',
          attr: 'status',
          source: 'To do',
          target: nil,
        }
        expect(
          positions_for('To do')
        ).to eq([['B', 1], ['C', 2], ['D', 3]])
        expect(
          positions_for(nil)
        ).to eq([['G', 1], ['A', 2], ['H', 3], ['I', 4]])
      end
    end

    context 'when there are a lot of items to update' do
      it 'updates 1000 positions' do
        contact_attrs = (1..1000).map do |position|
          {
            first_name: position.to_s,
            last_name: 'A',
            status: 'Finished',
          }
        end
        D::My::Contact.import(contact_attrs)
        contacts = D::My::Contact
          .where(status: 'Finished')
          .order(:id)

        contacts.each_with_index do |c, position|
          D::My::R::Position.create!(
            owner: c,
            context_value: D::My::Contact.statuses[c.status],
            context_attr: "status",
            value: position + 1
          )
        end

        moved = contacts.first
        target = contacts.last

        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: moved.id,
          target_id: target.id,
          direction: 'after',
          attr: 'status',
          source: 'Finished',
          target: 'Finished',
        }

        expected = contacts.drop(1).map.with_index(1) do |contact, position|
          [contact.first_name, position]
        end
        expected << [moved.first_name, 1000]

        expect(
          D::My::Contact
            .join_positions('status')
            .where(status: 'Finished')
            .order(value: :asc)
            .select('d_my_contacts.*, positions.value AS position_value')
            .map{|contact|[contact.first_name, contact.position_value]}
        ).to eq(expected)

        expect(
          D::My::Contact
            .join_positions('status')
            .where(status: 'Finished')
            .order(value: :asc)
            .select('d_my_contacts.*, positions.value AS position_value')
            .map { |contact| contact.position_value }
        ).to eq((1..1000).to_a)
      end
    end

    context 'when position_attribute is null' do
      it 'when moving between columns' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact1.id,#A
          target_id: @contact6.id,#F
          direction: 'before',
          attr: 'status',
          source: 'To do',
          target: 'Current',
        }
        expect(
          D::My::Contact
            .where(status: 'To do')
            .map{|c| c.first_name}
        ).not_to include('A')
        expect(
          D::My::Contact
            .where(status: 'Current')
            .map{|c| c.first_name}
        ).to include('A')
      end

      it 'when moving inside the same column' do
        patch :update_positions, params: {
          schema_name: 'my',
          klass_name: 'contacts',
          source_id: @contact2.id,#B
          target_id: @contact4.id,#D
          direction: 'before',
          attr: 'status',
          source: 'To do',
          target: 'To do',
        }
        expect(
          D::My::Contact
            .where(status: 'To do')
            .map{|c| c.first_name}
        ).to include('B')
      end
    end
  end
end
