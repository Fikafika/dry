module ActiveStorageAccessVariant

  PREDEFINED_VARIANTS = {
    'icon' => { format: 'png', resize_to_fill: [48, 48] },
    'attachment-icon' => { format: 'png', resize_to_limit: [64, 64] },
    'photo-button' => { format: 'png', resize_to_fill: [256, 256] },
    'preview' => { format: 'png', resize_to_limit: [800, 600] },
  }.freeze

  def variant(transformations)
    if transformations.is_a?(String)
      if t = ::ActiveStorageAccessVariant::PREDEFINED_VARIANTS[transformations]
        super(t)
      elsif transformations.start_with?('d_')
        super(transformations_for_dynamic_record_variant(transformations))
      else
        super(transformations)
      end
    else
      super(transformations)
    end
  end

  def transformations_for_dynamic_record_variant(str) # eg. d_uneek_account=logo=thumb
    klass_part, attachment_name, variant_name = str.split('=')
    klass_name_parts = klass_part.split('_')
    schema_name = klass_name_parts[1].classify_permalink
    raise_unknown_variant unless schema_name && attachment_name && variant_name
    schema = Dynamic::Schema.loaded_schemas[schema_name]
    Dynamic::Schema.load(schema_name) unless schema
    klass_name_parts.shift(2)
    route_key = klass_name_parts.join('_')
    klass = "D::#{schema_name}".constantize.const_get_by_route_key(route_key)
    variant = klass.reflect_on_attachment(attachment_name.to_sym).named_variants.fetch(variant_name.to_sym)
    raise_unknown_variant unless variant
    return variant.transformations
  end

  def raise_unknown_variant
    raise ActiveSupport::MessageVerifier::InvalidSignature
  end

end

ActiveSupport.on_load(:active_storage_blob) do
  prepend ActiveStorageAccessVariant
end