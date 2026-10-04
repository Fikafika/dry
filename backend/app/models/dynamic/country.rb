module Dynamic
  module Country
    module Feature; extend Dynamic::Feature

      ATTRIBUTES_BY_NAME = {
        'name_en' => {
          human_name_fr: 'Nom (anglais)',
          human_name_en: 'Name (english)',
          type: 'String',
        },
        'iso_code_a2' => {
          human_name_fr: 'Code ISO alpha 2',
          human_name_en: 'ISO code alpha 2',
          type: 'String',
        },
        'iso_code_a3' => {
          human_name_fr: 'Code ISO alpha 3',
          human_name_en: 'ISO code alpha 3',
          type: 'String',
        },
        'number' => {
          human_name_fr: 'Numéro ISO',
          human_name_en: 'ISO number',
          type: 'String',
        },
        'iso_long_name_en' => {
          human_name_fr: 'Nom Long (anglais)',
          human_name_en: 'Long name (english)',
          type: 'String',
        },
        'iso_short_name_en' => {
          human_name_fr: 'Nom court (anglais)',
          human_name_en: 'Short name (english)',
          type: 'String',
        },
        'ioc' => {
          human_name_fr: 'Code du Comité International Olympique',
          human_name_en: 'International Olympic Committee code',
          type: 'String',
        },
        'un_locode' => {
          human_name_fr: 'Code de localisation des Nations Unies',
          human_name_en: 'United Nations Location Code',
          type: 'String',
        },
        'gdpr_compliant' => {
          human_name_fr: 'Conforme au RGPD',
          human_name_en: 'RGPD compliant',
          type: 'Boolean',
        },
        'in_eu' => {
          human_name_fr: "Membre de l'Union Européenne",
          human_name_en: 'European Union member',
          type: 'Boolean',
        },
        'in_eea' => {
          human_name_fr: "Membre de l'Espace Economique Européenne",
          human_name_en: 'European Economic Area member',
          type: 'Boolean',
        },
        'in_eu_vat' => {
          human_name_fr: "Conforme à la TVA dans l'Union Européene",
          human_name_en: 'European Union VAT Area member',
          type: 'Boolean',
        },
        'in_esm' => {
          human_name_fr: "Membre du Marché Interieur Européen",
          human_name_en: 'European Single Market member',
          type: 'Boolean',
        },
        'longitude' => {
          human_name_fr: 'Longitude',
          human_name_en: 'Longitude',
          type: 'Float',
        },
        'latitude' => {
          human_name_fr: 'Latitude',
          human_name_en: 'Latitude',
          type: 'Float',
        },
        'max_latitude' => {
          human_name_fr: 'Latitude maximale',
          human_name_en: 'Maximal latitude',
          type: 'Float',
        },
        'min_latitude' => {
          human_name_fr: 'Latitude minimale',
          human_name_en: 'Minimum latitude',
          type: 'Float',
        },
        'max_longitude' => {
          human_name_fr: 'Longitude maximale',
          human_name_en: 'Maximum Longitude',
          type: 'Float',
        },
        'min_longitude' => {
          human_name_fr: 'Longitude minimale',
          human_name_en: 'Minimum longitude',
          type: 'Float',
        },
        'international_prefix' => {
          human_name_fr: "Préfixe d'appels internationaux",
          human_name_en: 'International call prefix',
          type: 'String',
        },
        'national_prefix' => {
          human_name_fr: "Préfixe d'appels nationaux",
          human_name_en: 'International call prefix',
          type: 'String',
        },
        'country_code' => {
          human_name_fr: 'Code pays',
          human_name_en: 'Country code',
          type: 'String',
        },
        'nanp_prefix' => {
          human_name_fr: "Préfixe du Plan de Numérotation Nord-Américain",
          human_name_en: 'North American Numbering Plan prefix',
          type: 'String',
        },
        'postal_code_format' => {
          human_name_fr: 'Format du code postal',
          human_name_en: 'Postal code format',
          type: 'String',
        },
        'address_format' => {
          human_name_fr: "Format de l'adresse",
          human_name_en: 'Address format',
          type: 'String',
        },
        'emoji_flag' => {
          human_name_fr: 'Emoji du drapeau',
          human_name_en: 'Flag emoji',
          type: 'String',
        },
        'distance_unit' => {
          human_name_fr: 'Unité de distance',
          human_name_en: 'Distance unit',
          type: 'String',
        },
        'nationality_en' => {
          human_name_fr: 'Nationalité (anglaise)',
          human_name_en: 'Nationality (english)',
          type: 'String',
        },
        'currency_iso_code' => {
          human_name_fr: 'Code iso de la monnaie',
          human_name_en: 'Money iso code',
          type: 'String',
        },
      }.freeze

      REVERSE_DEPENDENCIES = [
        'Dynamic::Timezone::Feature',
        'Dynamic::Currency::Feature',
      ].freeze

      IMPORT_NAME = 'From Dynamic Feature : Countries'.freeze

      def self.feature_attributes
        {
          # no dependency
          human_name_fr: 'Pays',
          human_name_en: 'Country',
          mandatory: false,
          enabled: false,
          options_attributes: [
            {
              name: 'european_membership',
              human_name_fr: "Ajout d'informations concernant le statut européen",
              human_name_en: 'Add informations about european status',
              type: 'Boolean',
              value: true
            },
            {
              name: 'other_geo_coord',
              human_name_fr: 'Ajout de coordonnées géographiques additionnelles',
              human_name_en: 'Add aditional geographic coordinates',
              type: 'Boolean',
              value: false
            },
            {
              name: 'country_klass',
              human_name_fr: 'Table des pays',
              human_name_en: "Countries table",
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klass',
              value: nil
            },
            {
              name: 'iso_code_a2_attribute',
              human_name_fr: 'Attribut du code ISO Alpha 2',
              human_name_en: "ISO code alpha 2 attribute",
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'iso_code_a3_attribute',
              human_name_fr: 'Attribut du code ISO Alpha 3',
              human_name_en: "ISO code alpha 3 attribute",
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'number_attribute',
              human_name_fr: 'Attribut du code ISO numérique',
              human_name_en: "ISO numeric code attribute",
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'name_en_attribute',
              human_name_fr: 'Attribut du nom anglais',
              human_name_en: "English name attribute",
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'iso_long_name_en_attribute',
              human_name_fr: 'Attribut du nom long',
              human_name_en: 'Long name attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'iso_short_name_en_attribute',
              human_name_fr: 'Attribut du nom court',
              human_name_en: 'Short name attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'address_format_attribute',
              human_name_fr: "Attribut du format de l'adresse",
              human_name_en: 'Address format attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'postal_code_format_attribute',
              human_name_fr: 'Attribut du format du code postal',
              human_name_en: 'Postal code format attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'distance_unit_attribute',
              human_name_fr: "Attribut de l'unité de longueur",
              human_name_en: 'Distance unit attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'longitude_attribute',
              human_name_fr: 'Attribut de la longitude',
              human_name_en: 'Longitude attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'latitude_attribute',
              human_name_fr: 'Attribut de la latitude',
              human_name_en: 'Latitude attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'country_code_attribute',
              human_name_fr: 'Attribut du code téléphonique',
              human_name_en: 'Phone code attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'international_prefix_attribute',
              human_name_fr: "Attribut du préfixe d'appels internationaux",
              human_name_en: 'International call prefix attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'national_prefix_attribute',
              human_name_fr: "Attribut du préfixe d'appels nationaux",
              human_name_en: 'National call prefix attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'nanp_prefix_attribute',
              human_name_fr: "Attribut du préfixe du Plan de Numérotation Nord-Américain",
              human_name_en: 'North American Numbering Plan prefix attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'gdpr_compliant_attribute',
              human_name_fr: 'Attribut de la conformité au RGPD',
              human_name_en: 'GDPR compliance attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'ioc_attribute',
              human_name_fr: 'Attribut du code du Comité International Olympique',
              human_name_en: 'International Olympic Committee code attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'un_locode_attribute',
              human_name_fr: 'Attribut du code de localisation des Nations Unies',
              human_name_en: 'United Nations Location Code attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'emoji_flag_attribute',
              human_name_fr: "Attribut de l'emoji du drapeau",
              human_name_en: 'Emoji flag attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'nationality_en_attribute',
              human_name_fr: 'Attribut de la nationalité',
              human_name_en: 'Nationality attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'currency_iso_code_attribute',
              human_name_fr: 'Attribut du code ISO de la monnaie',
              human_name_en: 'Iso code money attribute',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: nil
            },
            {
              name: 'update_countries',
              human_name_fr: 'Mettre à jour les pays',
              human_name_en: 'Update countries',
              type: 'Boolean',
              value: true
            },
          ]
        }
      end

      def self.after_disabled(feature)
        REVERSE_DEPENDENCIES.each do |d|
          dependency = feature.schema.features.find_by!(name: d)
          dependency&.update(enabled: false)
        end
      end

      def self.after_enabled(feature)
        country_schema_klass_option = feature.options.detect {|o| o.name == 'country_klass'}
        country_schema_klass = country_schema_klass_option&.value
        unless country_schema_klass
          country_schema_klass = feature.schema.klasses.create_with(
            human_name_fr: 'Pays',
            human_name_en: 'Country',
            plural_human_name_fr: 'Pays',
            plural_human_name_en: 'Countries',
            icon: 'globe',
            skip_create_default_forms: [:new],
            table_profile: :large,
          ).find_or_create_by!(name: 'Country')
          country_schema_klass_option.update(value: country_schema_klass)
        end

        attribute_options = feature.options.select {|o| o.name.ends_with?('attribute')}
        other_options = feature.options.select {|o| o.name.in?(['european_membership', 'other_geo_coord'])}.to_h {|o| [o.name, o.value]}

        mapped_attributes = self.create_and_map_attributes(country_schema_klass, attribute_options, other_options)
        csv = create_csv_to_import
        import = Dynamic::Import::Setting.find_by(name: IMPORT_NAME, schema_id: feature.schema_id)
        if import
          import.sources.first.csv.attach(ActiveStorage::Blob.create_and_upload!(io: csv, filename: 'countries.csv'))
        else
          import = Dynamic::Import::Setting.create!(
            name: IMPORT_NAME,
            schema: country_schema_klass.schema,
            actor: User.current,
            async: true,
            visible: false,
            sources_attributes: [
              {
                klass_name: country_schema_klass.const_absolute_name,
                csv: ActiveStorage::Blob.create_and_upload!(io: csv, filename: 'countries.csv'),
                type: 'Dynamic::Import::Source::Csv',
                has_title_line: true,
                column_delimiter: ';',
                encoding: 'UTF-8',
                columns_attributes: columns_for_import(country_schema_klass, mapped_attributes),
                cascades_attributes: [
                  {
                    klass_name: country_schema_klass.const_absolute_name,
                    keys: [
                      [ mapped_attributes['iso_code_a2_attribute'].name ],
                      [ mapped_attributes['iso_code_a3_attribute'].name ],
                      [ mapped_attributes['number_attribute'].name ],
                    ]
                  }
                ],
              }
            ],
          )
        end
      end

      def self.after_enabled_and_commit_schema(feature)
        update_countries = feature.options.detect {|o| o.name == 'update_countries'}
        if update_countries&.value
          import = Dynamic::Import::Setting.find_by(name: IMPORT_NAME, schema_id: feature.schema_id)
          job = import.create_init_job
          job.process_async
          update_countries.update!(value: false)
        end
        country_schema_klass = feature.schema.klasses.find_or_create_by!(name: 'Country')
        unless country_schema_klass.name_attribute_id
          name_attr_id = feature.options.detect {|o| o.name == 'name_en_attribute'}&.value_string
          country_schema_klass.update!(name_attribute_id: name_attr_id) if name_attr_id.present?
        end
      end

      def self.columns_for_import(schema_klass, mapped_attributes)
        result = []
        ATTRIBUTES_BY_NAME.keys.each_with_index do |default_attr_name, i|
          attr = schema_klass.attrs.detect {|a| a.name == default_attr_name}
          attr = mapped_attributes["#{default_attr_name}_attribute"] unless attr
          next unless attr
          result << { position: i, path: [0, attr.name] }
        end
        return result
      end

      def self.create_csv_to_import
        file = Tempfile.create('countries.csv')
        CSV.open(file, 'w', write_headers: true, col_sep: ';', headers: ATTRIBUTES_BY_NAME.keys) do |csv|
          ::ISO3166::Country.all.map do |c|
          csv << [
            c.translation('en'),
            c.alpha2,
            c.alpha3,
            c.number,
            c.iso_long_name,
            c.iso_short_name,
            c.ioc,
            c.un_locode,
            c.gdpr_compliant?,
            c.in_eu?,
            c.in_eea?,
            c.in_eu_vat?,
            c.in_esm?,
            c.longitude,
            c.latitude,
            c.max_latitude,
            c.min_latitude,
            c.max_longitude,
            c.min_longitude,
            c.international_prefix,
            c.national_prefix,
            c.country_code,
            c.nanp_prefix,
            c.postal_code_format,
            c.address_format,
            c.emoji_flag,
            c.distance_unit,
            c.nationality,
            c.currency_code
          ]
          end
        end
        return file
      end

      def self.create_and_map_attributes(klass, attribute_options, other_options = {})
        mapped_attribute_by_option_name = {}
        attrs = []

        attribute_options.each do |opt|
          if opt.value
            mapped_attribute_by_option_name[opt.name] = opt.value
            next
          end
          attr_name = opt.name.gsub(/_[a-z]*$/, '')
          attribute = klass.attrs.find_by(name: attr_name)
          if attribute
            mapped_attribute_by_option_name[opt.name] = attribute
            opt.update!(value: attribute)
          else
            attrs << ATTRIBUTES_BY_NAME[attr_name].merge(name: attr_name)
          end
        end

        if other_options['european_membership']
          ['in_eu', 'in_eea', 'in_esm', 'in_eu_vat'].each do |a|
            next if klass.attrs.where(name: a).exists?
            attrs << ATTRIBUTES_BY_NAME[a].merge(name: a)
          end
        end

        if other_options['other_geo_coord']
          ['max_latitude', 'min_latitude', 'max_longitude', 'min_longitude'].each do |a|
            next if klass.attrs.where(name: a).exists?
            attrs << ATTRIBUTES_BY_NAME[a].merge(name: a)
          end
        end

        if attrs.any?
          begin
            klass.attrs.create!(attrs)
          rescue ActiveRecord::RecordInvalid => e
            if e.record&.errors&.first&.type == 'limit_exceeded'
              klass.reload # Some attributes might be created but not assigned to "attrs" association
              klass.migrate_to_table_profile(:large)
              attrs_created = klass.attrs.map(&:name)
              remaining_attrs = attrs.reject {|a| a[:name].in?(attrs_created)}
              klass.attrs.create!(remaining_attrs)
            else
              raise
            end
          end

          attrs.each do |hash|
            opt_name = hash[:name] + '_attribute'
            next if mapped_attribute_by_option_name.has_key?(opt_name)
            opt = attribute_options.detect {|opt| opt.name == opt_name}
            next unless opt
            new_attribute = klass.attrs.detect {|a| a.name == hash[:name]}
            mapped_attribute_by_option_name[opt.name] = new_attribute
            opt.update!(value: new_attribute)
          end
        end

        return mapped_attribute_by_option_name
      end

    end
  end
end
