ActiveSupport.on_load(:dynamic_schema_base) do

  include MassAssignmentSkipUnknownAttributes
  include HyperResourceBroadcastUpdate

  concern :ChangeUpdateAutocompleteFilters do
    included do
      after_update :update_autocomplete_filters, if: :name_previously_changed?
    end

    def update_autocomplete_filters
      klass_name = (self.try(:owner_klass) || self.try(:klass)).const_absolute_name
      Dynamic::Form::Element::Association::BelongsTo
      Dynamic::Form::Element::Association::HasMany
      Dynamic::Form::Element::Association::Base.where(schema_id: self.schema_id).where('autocomplete_filters IS NOT NULL AND autocomplete_filters::text LIKE ?', "%#{self.name_previously_was}%").find_each do |e|
        e.rename_autocomplete_filters(klass_name, self.name_previously_was, self.name)
      end
    end
  end

end
