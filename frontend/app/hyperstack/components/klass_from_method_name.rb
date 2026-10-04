module KlassFromMethodName; extend ActiveSupport::Concern

  class_methods do

    def klass_from_method_name(record_class, method_name, raise_if_missing: true)
      if reflection = record_class.reflect_on_association_from_method_name(method_name)
        "#{self.name}::Association::#{reflection.class.name.demodulize.gsub(/Reflection\z/, '')}".safe_constantize || self::Association::Base
      elsif record_class.attributes[method_name]
        "#{self.name}::Attribute::#{record_class.attributes[method_name]['type'].classify}".safe_constantize || self::Attribute::Base
      elsif record_class.reflect_on_attachment(method_name) || (record_class.reflect_on_all_attachments && record_class.reflect_on_attachment(method_name)) # TODO fix HyperResource and remove code after ||
        "#{self.name}::Attachment::#{record_class.reflect_on_attachment(method_name).macro.classify}".safe_constantize || self::Attachment::Base
      elsif self.translatable?(method_name)
        "#{self.name}::Attribute::#{record_class.attributes[remove_locale_from_name(method_name)]['type'].classify}".safe_constantize || self::Attribute::Base
      elsif method_name == 'type'
        self::Attribute::Base
      elsif raise_if_missing
        raise "unknown #{method_name} for #{record_class&.name}"
      else
        nil
      end
    end

    private

    def translatable?(method_name)
      return method_name && !!I18n.available_locales.detect{|l| method_name.end_with?("_#{l}")}
    end

    def remove_locale_from_name(method_name)
      l = I18n.available_locales.detect{|l| method_name.end_with?("_#{l}")}
      method_name.sub(/_#{l}$/, '')
    end

  end

end
