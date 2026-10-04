module Dynamic
  module Company
    module Organization
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__organization__, klass, concern)

        c = klass.const.__organization_config
        c[:name] = concern.options.detect {|o| o.name == 'name_attribute'}&.value&.name
        c[:siren] = concern.options.detect {|o| o.name == 'siren_attribute'}&.value&.name
        c[:legal_category] = concern.options.detect {|o| o.name == 'legal_category_attribute'}&.value&.name
        c[:creation_date] = concern.options.detect {|o| o.name == 'creation_date_attribute'}&.value&.name
        c[:closing_date] = concern.options.detect {|o| o.name == 'closing_date_attribute'}&.value&.name
        c[:logo_attachment] = concern.options.detect {|o| o.name == 'logo_attachment'}&.value&.name
        c[:establissement_association] = concern.options.detect {|o| o.name == 'establissement_association'}&.value&.name
        c[:headquarters_siret] = concern.options.detect {|o| o.name == 'headquarters_siret_attribute'}&.value&.name

        klass.const.include(Synchronizable)
      end

      module Synchronizable; extend ActiveSupport::Concern
        included do
          after_update :rematch_establissements, if: :rematch_establissements?

          delegate *[
            :rematch_establissements,
            :rematch_establissements?,
          ], to: :__organization__
        end
      end

      class Proxy < Dynamic::Concern::Proxy
        attr_accessor :skip_rematch_callback

        def rematch_establissements?
          !skip_rematch_callback && siren_attribute_previously_changed?
        end

        def rematch_establissements
          establissement_association.find_each do |establissement|
            establissement.__organization_establissement__.rematch_organization
          end
        end
      end
    end
  end
end
