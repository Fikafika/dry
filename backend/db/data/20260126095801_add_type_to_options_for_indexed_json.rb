# frozen_string_literal: true

class AddTypeToOptionsForIndexedJson < ActiveRecord::Migration[8.0]
  def add_types(change)
    ::OpenSearch::Model.client.wait_for_server
    Dynamic::Schema.find_each do |schema|
      schema.klasses.each do |klass|
        begin
          options_for_indexed_json = klass.options_for_indexed_json_deserialized
          original = options_for_indexed_json.deep_dup
          klass.travel_in_options_for_indexed_json(options_for_indexed_json) do |o, klass, parent, travel|
            if parent.is_a?(::Dynamic::Schema::Association::Base)
              next unless o[:only].is_a?(Array)
              if change == :up
                if !o[:only].include?('type')
                  index_id = o[:only].index('id')
                  unless index_id
                    puts "Missing id key on Klass #{klass.id}"
                    next
                  end
                  i = index_id + 1
                  o[:only].insert(i, 'type')
                end
              elsif change == :down
                if o[:only].include?('type') && !parent.target_klass.nil?
                  o[:only].delete('type')
                end
              end
            end
          end
          if original != options_for_indexed_json
            klass.options_for_indexed_json = options_for_indexed_json
            begin
              schema.load unless schema.loaded?
              klass.save!
            rescue OpenSearch::Transport::Transport::Errors::NotFound => e
              puts e.message
            end
          end
        rescue
          puts "an error occured when migrate types of #{klass.name}:"
          raise
        end
      end
    end
  end

  def up
    add_types(:up)
  end

  def down
    add_types(:down)
  end

end
