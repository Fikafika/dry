module Dynamic
  module Company
    module Establissement
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__organization_establissement__, klass, concern)

        c = klass.const.__organization_establissement_config
        c[:name] = concern.options.detect {|o| o.name == 'name_attribute'}&.value&.name
        c[:siret] = concern.options.detect {|o| o.name == 'siret_attribute'}&.value&.name
        c[:legal_category] = concern.options.detect {|o| o.name == 'legal_category_attribute'}&.value&.name
        c[:creation_date] = concern.options.detect {|o| o.name == 'creation_date_attribute'}&.value&.name
        c[:closing_date] = concern.options.detect {|o| o.name == 'closing_date_attribute'}&.value&.name
        c[:logo_attachment] = concern.options.detect {|o| o.name == 'logo_attachment'}&.value&.name
        c[:organization_association] = concern.options.detect {|o| o.name == 'organization_association'}&.value&.name

        klass.const.include(Synchronizable)
      end

      module Synchronizable; extend ActiveSupport::Concern
        included do
          after_create :match_organization, if: :match_organization?
          after_update :rematch_organization, if: :rematch_organization?

          delegate *[
            :match_organization,
            :match_organization?,
            :rematch_organization,
            :rematch_organization?,
          ], to: :__organization_establissement__
        end
      end

      class Proxy < Dynamic::Concern::Proxy
        attr_accessor :skip_rematch_callback

        def match_organization?
          organization_association&.id.nil?
        end

        def rematch_organization?
          return if skip_rematch_callback || match_organization?
          return siret_attribute_previously_changed? || (extract_siren.blank? && name_attribute_previously_changed?)
        end

        def rematch_organization
          with_skipped_callback do
            self.organization_association = nil
            @record.save!
          end

          match_organization if match_organization?
        end

        def match_organization
          siren = extract_siren
          name = name_attribute

          return unless siren.present? || name.present?

          organization = organization_klass.find_by(siren: siren) if siren
          organization ||= organization_klass.where(siren: [nil, '']).detect {|c| normalize_name(c.name) == normalize_name(name)} if name.present?
          organization ||= organization_klass.new

          op = organization.__organization__

          update_organization(op, siren, name)
          save_organization_without_cascading_rematch(organization)

          with_skipped_callback do
            self.organization_association = organization
            @record.save!
          end
        end

        private

        def organization_klass
          @record.class.reflect_on_association(@config[:organization_association]).klass
        end

        def extract_siren
          siret_digits = siret_attribute && siret_attribute.to_s.gsub(/\D/, '')
          return siret_digits[0, 9] if siret_digits && siret_digits&.length >= 9
          nil
        end

        def update_organization(op, siren, name)
          op.siren_attribute = siren if op.siren_attribute.blank? && siren.present?
          op.name_attribute = name if op.name_attribute.blank? && name.present?
          op.headquarters_siret_attribute = siret_attribute if op.headquarters_siret_attribute.blank? && siret_attribute.present?

          update_earliest_date(op)
          update_latest_date(op)

          if @config[:legal_category_attribute] && legal_category_attribute.present? && op.legal_category_attribute.blank?
            op.legal_category_attribute = legal_category_attribute
          end

          attach_logo(op)
        end

        def update_earliest_date(op)
          return unless @config[:creation_date_attribute]

          establissement_creation_date = creation_date_attribute
          return unless establissement_creation_date

          organization_creation_date = op.creation_date_attribute

          if organization_creation_date.nil? || establissement_creation_date < organization_creation_date
            op.creation_date_attribute = establissement_creation_date
          end
        end

        def update_latest_date(op)
          return unless @config[:closing_date_attribute]

          establissement_closing_date = closing_date_attribute
          return unless establissement_closing_date

          organization_closing_date = op.closing_date_attribute

          if organization_closing_date.nil? || establissement_closing_date > organization_closing_date
            op.closing_date_attribute = establissement_closing_date
          end
        end

        def attach_logo(op)
          return unless @config[:logo_attachment]

          establissement_logo = logo_attachment
          organization_logo = op.logo_attachment
          organization_logo.attach(establissement_logo.blob) if establissement_logo&.attached? && !organization_logo&.attached?
        end

        def normalize_name(name)
          name.to_s.classify_permalink
        end

        def save_organization_without_cascading_rematch(organization)
          organization.__organization__.skip_rematch_callback = true
          organization.save!
        ensure
          organization.__organization__.skip_rematch_callback = false
        end

        def with_skipped_callback
          self.skip_rematch_callback = true
          yield
        ensure
          self.skip_rematch_callback = false
        end
      end
    end
  end
end
