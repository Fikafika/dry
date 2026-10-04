class AddThemeToCommunities < ActiveRecord::Migration[6.0]
  def change
    add_reference :communities, :theme, type: :uuid
    add_column :dynamic_themes, :community_appearance, :boolean, default: false
  end
end
