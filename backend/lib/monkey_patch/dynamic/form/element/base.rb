ActiveSupport.on_load(:dynamic_form_element_base) do
  include MassAssignmentSkipUnknownAttributes

  concerning :RenameAutocompleteFilters do

    def rename_autocomplete_filters(klass_name, old_name, new_name)
      return unless self.target_klass&.name == klass_name

      in_autocomplete_filters do |hash|
        k = hash.keys.first
        case k
        when 'or', 'and', 'variable'
        else
          if k == old_name
            new_key = new_name
            hash[new_key] = hash.delete(k)
          end
        end
      end

      if autocomplete_filters_changed?
        self.save
      end
    end

    private

    def in_autocomplete_filters(n = self.autocomplete_filters, &block)
      case n
      when Array
        n.each{|v| in_autocomplete_filters(v, &block) }
      when Hash
        yield(n)
        n.each do |k, v|
          in_autocomplete_filters(v, &block)
        end
      end
    end

  end

end
