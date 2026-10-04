module Icon; extend ActiveSupport::Concern

  class_methods do
    def icon
      return @icon if @icon_loaded
      klass = self
      result = nil
      while !result.present? && klass != Object do
        result = ::I18n.t("icons.models.#{klass.i18n_key}", default: '')
        klass = klass.superclass
      end
      @icon_loaded = true
      @icon = result.present? ? result : nil
      return @icon
    end
  end

end
