class CreateCasSessionTicketsTable < ActiveRecord::Migration[6.0]
  def up
    DeviseCasAuthenticatable::CasSessionTicket.create_table!
  end

  def down
    DeviseCasAuthenticatable::CasSessionTicket.drop_table!
  end
end