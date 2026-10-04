# frozen_string_literal: true

class AddSearchableFieldsToEmailIndexing < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.klasses.select { |klass| klass.name == 'Email' }.each do |klass|
        # Update options_for_indexed_json (indexation)
        options = klass.options_for_indexed_json_deserialized || {}
        original_options = options.deep_dup

        # Check to modify 'only'
        tag_needs_update = !options['only']&.include?('tag')
        address_needs_update = !options['only']&.include?('address')

        # Check to modify 'include.owner'
        owner_options = options.dig('include', 'owner')
        default_owner_only = ['id', 'created_at', 'updated_at', 'deleted_at', 'polymorphic_name', 'type']
        owner_needs_update = owner_options.nil? || default_owner_only.any? { |field| !owner_options['only']&.include?(field) }

        # Update 'only' if needed
        if tag_needs_update
          options['only'] ||= []
          options['only'] << 'tag'
        end

        # Update 'address' in 'only' if needed
        if address_needs_update
          options['only'] ||= []
          options['only'] << 'address'
        end

        # Update 'include.owner' if needed
        if owner_needs_update
          options['include'] ||= {}
          if owner_options.nil?
            options['include']['owner'] = { 'only' => default_owner_only.dup }
          else
            owner_options['only'] ||= []
            default_owner_only.each do |field|
              owner_options['only'] << field
            end
          end
        end

        if original_options != options
          klass.options_for_indexed_json = options
        end

        # Update global_search_fields (research)
        original_global_search = klass.global_search_fields.dup
        global_search = klass.global_search_fields || []
        global_search = global_search.dup if global_search.is_a?(Array)
        global_search ||= []

        # Check to modify global_search_fields
        owner_search_needs_update = !global_search.include?('owner.polymorphic_name')
        tag_search_needs_update = !global_search.include?('tag')
        address_search_needs_update = !global_search.include?('address')

        # Update 'owner.polymorphic_name' if needed
        if owner_search_needs_update
          global_search << 'owner.polymorphic_name'
        end

        # Update 'address' if needed
        if address_search_needs_update
          global_search << 'address'
        end

        if original_global_search != global_search
          klass.global_search_fields = global_search
        end

        # Save if either changed
        if original_options != options || original_global_search != global_search
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

  def down
    # no operation, data migrations are typically one-way
  end
end
