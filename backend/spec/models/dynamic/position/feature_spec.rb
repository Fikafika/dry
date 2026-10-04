describe Dynamic::Position::Feature do
  before(:each) do
    @schema = Dynamic::Schema.create!(
      name: 'My',
      klasses_attributes: [{
        id: "8993fd99-572b-4718-8827-a7ce78a4b70f",
        name: 'Contact',
        attrs_attributes: [
          {
            name: 'first_name',
            type: 'String',
          },
          {
            name: 'last_name',
            type: 'String',
          },
          {
            name: 'status',
            type: 'Enum',
            values_attributes: [
              { name: 'Saved' },
              { name: 'Blocked' }
            ]
          },
          {
            name: 'state',
            type: 'Enum',
            values_attributes: [
              { name: 'Open' },
              { name: 'Closed' }
            ]
          }
        ],
      }]
    )

    @schema.load

    contact_attrs1 = (1..10).map do |position|
      {
        first_name: "A_#{position}",
        last_name: 'A',
        status: 'Saved',
        state: 'Open'
      }
    end

    contact_attrs2 = (1..10).map do |position|
      {
        first_name: "B_#{position}",
        last_name: 'B',
        status: 'Blocked',
        state: 'Closed'
      }
    end

    contact_attrs3 = (1..5).map do |position|
      {
        first_name: "C_#{position}",
        last_name: 'C',
        status: nil,
        state: nil
      }
    end

    D::My::Contact.import(contact_attrs1)
    D::My::Contact.import(contact_attrs2)
    D::My::Contact.import(contact_attrs3)

    D::My::Contact.where(status: 'Saved').each_with_index do |contact, index|
      D::My::R::Position.create!(
        owner: contact,
        context_value: D::My::Contact.statuses[contact.status],
        context_attr: 'status',
        value: index
      )
    end

    D::My::Contact.where(status: 'Blocked').each_with_index do |contact, index|
      D::My::R::Position.create!(
        owner: contact,
        context_value: D::My::Contact.statuses[contact.status],
        context_attr: 'status',
        value: index
      )
    end

    D::My::Contact.where(status: nil).each_with_index do |contact, index|
      D::My::R::Position.create!(
        owner: contact,
        context_value: nil,
        context_attr: 'status',
        value: index
      )
    end
  end

  describe '.join_positions' do
    it 'returns the position for a non-nil enum value' do
      result = D::My::Contact
        .join_positions("status")
        .where(first_name: 'A_5')
        .select('d_my_contacts.*, positions.value AS position_value')

      expect(result.first.position_value).to eq(4)
    end


    it 'does not return the position for another enum uuid' do
      contact = D::My::Contact.where(first_name: 'A_5').first

      D::My::R::Position.create!(
        owner: contact,
        context_value: D::My::Contact.statuses['Blocked'],
        context_attr: 'status',
        value: 100
      )

      result = D::My::Contact
        .join_positions("status")
        .where(first_name: 'A_5')
        .select('d_my_contacts.*, positions.value AS position_value')

      expect(result.first.position_value).to eq(4)
    end

    it 'returns the position when both the enum value and context value are nil' do
      result = D::My::Contact
        .join_positions("status")
        .where(first_name: 'C_5')
        .select('d_my_contacts.*, positions.value AS position_value')

      expect(result.first.position_value).to eq(4)
    end

    it 'does not mix positions between different context attributes' do
      contact = D::My::Contact.where(first_name: 'C_5').first

      D::My::R::Position.create!(
        owner: contact,
        context_value: nil,
        context_attr: 'status',
        value: 100
      )

      D::My::R::Position.create!(
        owner: contact,
        context_value: nil,
        context_attr: 'state',
        value: 200
      )

      status_result = D::My::Contact
        .join_positions("status")
        .where(first_name: 'C_5')
        .select('d_my_contacts.*, positions.value AS position_value')

      state_result = D::My::Contact
        .join_positions("state")
        .where(first_name: 'C_5')
        .select('d_my_contacts.*, positions.value AS position_value')

      expect(status_result.map(&:position_value)).to contain_exactly(4, 100)
      expect(state_result.first.position_value).to eq(200)
    end
  end
end