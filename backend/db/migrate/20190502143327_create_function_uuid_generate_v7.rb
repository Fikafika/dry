class CreateFunctionUuidGenerateV7 < ActiveRecord::Migration[6.0]
  def change
    create_function :uuid_generate_v7
  end
end
