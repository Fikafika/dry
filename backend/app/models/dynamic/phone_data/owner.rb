module Dynamic
  module PhoneData
    module Owner; extend ActiveSupport::Concern

      def self.before_included(klass, concern)
        option = concern.options.detect {|o| o.name == 'phone_number'}
        self.define_method('_phone_data_number_attribute_name') do
          return option&.value&.name
        end
      end

      included do
        before_save :update_phone_data, if: :saving_phone_number?

        def update_phone_data
          parsed_phone = Phonelib.parse(number)

          self.phone_locality = parsed_phone.geo_name if self.respond_to?(:phone_locality)
          self.phone_carrier = parsed_phone.carrier if self.respond_to?(:phone_carrier)

          if self.respond_to?(:phone_categories)
            categories_to_remove = phone_categories_to_remove(parsed_phone.types)
            self.phone_categories.each { |t| self.phone_categories.delete(t) if categories_to_remove.include?(t.label_en) }
            parsed_phone.types.each do |t|
              t_label = Phonelib::Core::TYPES_DESC[t]
              next if self.phone_categories.detect {|pt| pt.label_en == t_label}
              cat = self.phone_categories.klass.find_or_create_by(label_en: t_label)
              self.phone_categories.add_without_save(cat)
            end
          end

          if self.respond_to?(:timezones)
            new_timezones = case parsed_phone.timezone
            when Array
              parsed_phone.timezone
            when String
              [parsed_phone.timezone]
            else
              []
            end
            existing_timezones = self.timezones.map(&:tz_id)
            timezones_to_remove = existing_timezones - new_timezones
            self.timezones.each do |t|
              self.timezones.delete(t) if timezones_to_remove.include?(t.tz_id)
            end
            new_timezones.each do |t|
              next if existing_timezones.include?(t)
              tz = self.timezones.klass.find_or_create_by(tz_id: t)
              self.timezones.add_without_save(tz)
            end
          end
        end

        private

        def saving_phone_number?
          self.send("will_save_change_to_#{_phone_data_number_attribute_name}?")
        end

        def phone_categories_to_remove(new_categories)
          return self.phone_categories.map(&:label_en) - new_categories.map {|t| I18n.t("phone.type.#{t}", locale: :en)}
        end

      end

    end
  end
end