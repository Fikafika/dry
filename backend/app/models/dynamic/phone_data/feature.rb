module Dynamic
  module PhoneData
    module Feature; extend Dynamic::Feature

      ATTRIBUTES = {
        carrier: {
          name: 'phone_carrier',
          human_name_fr: 'Opérateur',
          human_name_en: 'Carrier',
          type: 'String'
        },
        locality: {
          name: 'phone_locality',
          human_name_fr: 'Localité',
          human_name_en: 'Locality',
          type: 'String'
        },
      }.freeze

      def self.feature_attributes
        {
          # optional dependency with timezone
          human_name_fr: 'Données additionnelles de téléphone',
          human_name_en: 'Additional phone data',
          mandatory: false,
          enabled: false,
          concern_templates_attributes: [
            {
              name: 'Owner',
              human_name_fr: 'Propriétaire',
              human_name_en: 'Owner',
              template: true,
              options_attributes: [
                {
                  name: 'phone_number',
                  human_name_fr: "Attribut numéro de téléphone",
                  human_name_en: "Phone number attribute",
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'carrier_attribute',
                  human_name_fr: "Récupération de l'opérateur",
                  human_name_en: 'Retrieve carrier',
                  type: 'Boolean',
                  value: true
                },
                {
                  name: 'timezone_association',
                  human_name_fr: 'Récupération des fuseaux horaires',
                  human_name_en: 'Retrieve timezones',
                  type: 'Boolean',
                  value: true
                },
                {
                  name: 'category_association',
                  human_name_fr: 'Récupération de la catégorie',
                  human_name_en: 'Retrieve category',
                  type: 'Boolean',
                  value: true
                },
                {
                  name: 'locality_attribute',
                  human_name_fr: 'Récupération de la localité',
                  human_name_en: 'Retrieve locality',
                  type: 'Boolean',
                  value: true
                },
              ],
            },
          ],
          options_attributes: [
            {
              name: 'synchronize_phone_data_after_enable',
              human_name_fr: 'Synchroniser les données de téléphones après activation de la feature',
              human_name_en: 'Synchonize phone data after enabling feature',
              type: 'Boolean',
              value: false
            },
          ]
        }
      end

      def self.after_enabled(feature)
        concerns = feature.concerns.select {|c| c.name == 'Owner'}
        has_timezone_dependency = concerns.detect {|c| c.options.detect {|o| o.name == 'timezone_association'}&.value }

        if has_timezone_dependency
          dependency = feature.schema.features.find_by!(name: 'Dynamic::Timezone::Feature')
          unless dependency.enabled
            feature.errors.add(:enabled, :dependent, name: dependency.human_name)
            raise ActiveRecord::RecordInvalid.new(feature)
          end
          self.add_timezones_association(concerns)
        end

        self.add_attributes(concerns)
        self.add_categories_association(concerns)
      end

      def self.after_enabled_and_commit_schema(feature)
        phone_category_klass = feature.schema.klasses.detect {|k| k.name == 'PhoneCategory'}
        concerns = feature.concerns.select {|c| c.name == 'Owner'}
        if phone_category_klass
          feature.schema.load
          self.create_categories(phone_category_klass.const)
        end

        synchonization_option = feature.options.detect {|o| o.name == 'synchronize_phone_data_after_enable'}
        if synchonization_option&.value
          synchonization_option.update!(value: false)
          Dynamic::PhoneData::Feature.update_klasses_async(concerns)
        end
      end

      def self.add_timezones_association(concerns)
        timezone_klass = nil
        concerns.each do |c|
          next unless c.options.detect {|o| o.name == 'timezone_association'}&.value
          timezone_klass ||= c.schema.klasses.detect {|k| k.name == 'Timezone'}
          klass = c.schema.klasses.detect {|k| k.id == c.klass_id}

          klass.associations.create_with(
            human_name_fr: 'Fuseaux Horraires',
            human_name_en: 'Timezones',
            skip_create_default_forms: [:new],
          ).find_or_create_by(
            name: 'timezones',
            type: 'HasMany',
            target_klass: timezone_klass,
          )
        end
      end

      def self.add_attributes(concerns)
        concerns.each do |c|
          attr_options = c.options.select {|o| o.name.end_with?('attribute')}
          selected_attrs = []
          attr_options.each do |a|
            next unless a.value
            attr_name = a.name.split('_')[0].to_sym
            next if c.klass.attrs.where(name: ATTRIBUTES.dig(attr_name, :name)).exists?
            selected_attrs << ATTRIBUTES[attr_name]
          end
          c.klass.attrs.create!(selected_attrs) unless selected_attrs.empty?
        end
      end

      def self.add_categories_association(concerns)
        phone_category_klass = nil
        concerns.each do |c|
          next unless c.options.detect {|o| o.name == 'category_association'}&.value
          phone_category_klass ||= self.create_phone_category_klass(c.schema)
          klass = c.schema.klasses.detect {|k| k.id == c.klass_id}

          klass.associations.create_with(
            human_name_fr: 'Catégories',
            human_name_en: 'Categories',
            skip_create_default_forms: [:new],
          ).find_or_create_by(
            name: 'phone_categories',
            type: 'HasMany',
            target_klass: phone_category_klass
          )
        end
      end

      def self.create_phone_category_klass(schema)
        phone_category_klass = schema.klasses.create_with(
          human_name_fr: 'Catégorie de téléphone',
          human_name_en: 'Phone category',
          plural_human_name_fr: 'Catégories de téléphone',
          plural_human_name_en: 'Phone categories',
          icon: 'phone-square',
          skip_create_default_forms: [:new],
          table_profile: :small,
        ).find_or_create_by!(name: 'PhoneCategory')

        name_attribute = phone_category_klass.attrs.create_with(
          type: 'String',
          human_name_en: 'label (english)',
          human_name_fr: 'libellé (anglais)'
        ).find_or_create_by!(name: 'label_en')

        phone_has_many = phone_category_klass.associations.create_with(
          human_name_fr: 'Téléphones',
          human_name_en: 'Phones',
          skip_create_default_forms: [:new],
        ).find_or_create_by(
          name: 'phones',
          type: 'HasMany',
        )
        return phone_category_klass
      end

      def self.create_categories(dynamic_klass)
        return unless dynamic_klass
        attrs = Phonelib::Core::TYPES_DESC.map do |k, v|
          {label_en: v}
        end
        dynamic_klass.import(attrs) if dynamic_klass.count == 0
      end

      def self.update_klasses_async(concerns)
        concerns.each do |c|
          schema_klass_name = c.klass.const_absolute_name
          notification = create_notification(schema_klass_name)
          perform_params = {
            klass_name: schema_klass_name,
            user_id: User.current&.id,
            notification: notification,
          }.deep_stringify_keys
          ::Dynamic::PhoneData::Worker.perform_async(perform_params)
        end
      end

      def self.create_notification(klass_name)
        notification_klass = klass_name.safe_constantize.module_parent::R::Notification
        title = I18n.t('phone.titles.synchronize', klass: klass_name.safe_constantize.model_name.human(count: 2).downcase)
        return notification_klass&.create!(
          user_id: User.current&.id,
          title: title,
          klass_name: 'PhoneData',
          total: klass_name.safe_constantize&.count,
          data: {klass_name: klass_name},
          can_cancel: true,
        )
      end
    end
  end
end
