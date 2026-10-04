# frozen_string_literal: true

class RemoveDuplicateOptionsForEventFeatureConcerns < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Event::Feature'}
      next unless feature
      concern_features = feature.concern_templates.select {|ct| ct.name == 'Indisponibility'} + feature.concerns.select {|ct| ct.name == 'Indisponibility'}
      concern_features.each do |c|
        assoc_options = c.options.select {|o| o.name == 'indisponibility_assoc'}
        if assoc_options.length > 1
          ordered_assoc_options = assoc_options.sort_by(&:created_at)
          ordered_assoc_options.drop(1).each {|o| o.destroy! }
        end
        klass_options = c.options.select {|o| o.name == 'event_klass'}
        if klass_options.length > 1
          ordered_klass_options = klass_options.sort_by(&:created_at)
          ordered_klass_options.drop(1).each {|o| o.destroy! }
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
