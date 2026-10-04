module Dynamic
  module Communication
    module Address
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        mandatory = [:street, :second_street, :third_street, :city, :zip_code, :county, :state, :country, :latitude, :longitude, :owner_association]
        proxify_concern(:__address__, klass, concern, mandatory: mandatory)

        c = klass.const.__address_config

        c[:street] = concern.options.detect{|o| o.name == 'street_attribute'}&.value&.name
        c[:second_street] = concern.options.detect{|o| o.name == 'second_street_attribute'}&.value&.name
        c[:third_street] = concern.options.detect{|o| o.name == 'third_street_attribute'}&.value&.name
        c[:city] = concern.options.detect{|o| o.name == 'city_attribute'}&.value&.name
        c[:zip_code] = concern.options.detect{|o| o.name == 'zip_code_attribute'}&.value&.name
        c[:county] = concern.options.detect{|o| o.name == 'county_attribute'}&.value&.name
        c[:state] = concern.options.detect{|o| o.name == 'state_attribute'}&.value&.name
        c[:country] = concern.options.detect{|o| o.name == 'country_attribute'}&.value&.name
        c[:latitude] = concern.options.detect{|o| o.name == 'latitude_attribute'}&.value&.name
        c[:longitude] = concern.options.detect{|o| o.name == 'longitude_attribute'}&.value&.name
        c[:owner_association] = concern.options.detect{|o| o.name == 'owner_association'}&.value&.name
      end

      class Proxy <  Dynamic::Concern::Proxy
      end
    end
  end
end
