# frozen_string_literal: true

class AddPolymoprhicNameToOptionsForIndexedJson < ActiveRecord::Migration[6.0]

  def change_polymoprhic_names(change)
    Dynamic::Schema.find_each do |schema|
      schema.klasses.each do |klass|
        options_for_indexed_json = klass.options_for_indexed_json_deserialized
        original = options_for_indexed_json.deep_dup
        klass.travel_in_options_for_indexed_json(options_for_indexed_json) do |o, klass, parent, travel|
          next unless parent.is_a?(::Dynamic::Schema::Association::Base) && parent.target_klass.nil?
          next unless o[:only].is_a?(Array)
          if change == :up
            if !o[:only].include?('polymorphic_name')
              o[:only] << 'polymorphic_name'
            end
          elsif change == :down
            if o[:only].include?('polymorphic_name')
              o[:only].delete('polymorphic_name')
            end
          end
        end
        if original != options_for_indexed_json
          klass.options_for_indexed_json = options_for_indexed_json
          begin
            schema.load unless schema.loaded?
            klass.save
          rescue OpenSearch::Transport::Transport::Errors::NotFound => e
            puts e.message
          end
        end
      end
    end
  end

  def up
    change_polymoprhic_names(:up)
  end

  def down
    change_polymoprhic_names(:down)
  end
end
