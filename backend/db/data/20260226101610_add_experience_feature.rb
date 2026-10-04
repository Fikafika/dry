class AddExperienceFeature < ActiveRecord::Migration[8.0]
  def change
    Dynamic::Schema.find_each do |schema|
      next if schema.features.detect {|f| f.name == 'Dynamic::Experience::Feature'}
      schema.create_feature('Dynamic::Experience::Feature')
    end
  end
end
