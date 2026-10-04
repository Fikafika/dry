module Dynamic
  module Currency
    module Feature; extend Dynamic::Feature

      ATTRIBUTES = [
        'iso_code',
        'name',
        'priority',
        'exponent',
        'symbol',
        'disambiguate_symbol',
        'html_entity',
        'symbol_first',
        'subunit',
        'subunit_to_unit',
        'thousand_separator',
        'decimal_mark',
        'smallest_denomination',
      ].freeze

      DEPENDENCIES = ['Dynamic::Country::Feature'].freeze

      IMPORT_NAME = 'From Dynamic Feature : Currencies'.freeze

      def self.feature_attributes
        {
          # no dependency
          human_name_fr: 'Devise',
          human_name_en: 'Currency',
          mandatory: false,
          enabled: false,
          options_attributes: [
            {
              name: 'update_currencies',
              human_name_fr: 'Mettre à jour les devises',
              human_name_en: 'Update currencies',
              type: 'Boolean',
              value: true
            },
          ]
        }
      end

      def self.after_enabled(feature)
        DEPENDENCIES.each do |d|
          dependency = feature.schema.features.find_or_create_by!(name: d)
          unless dependency.enabled
            feature.errors.add :enabled, :dependent, name: dependency.human_name
            raise ActiveRecord::RecordInvalid.new(feature)
          end
        end

        currency_schema_klass = feature.schema.klasses.create_with(
          name: 'Currency',
          human_name_fr: 'Devise',
          human_name_en: 'Currency',
          plural_human_name_fr: 'Devises',
          plural_human_name_en: 'Currencies',
          icon: 'coins',
          table_profile: :medium,
        ).find_or_create_by!(name: 'Currency')

        country_feature = feature.schema.features.find_by(name: 'Dynamic::Country::Feature')
        country_schema_klass = country_feature.options.detect {|o| o.name == 'country_klass'}&.value

        unless country_schema_klass
          feature.errors.add :enabled
          raise ActiveRecord::RecordInvalid.new(feature)
        end

        self.create_attributes(currency_schema_klass)
        currency_assoc = self.create_associations(currency_schema_klass, country_schema_klass, feature)

        csv = create_csv_to_import
        import = Dynamic::Import::Setting.find_by(name: IMPORT_NAME, schema_id: feature.schema_id)
        if import
          import.sources.first.csv.attach(ActiveStorage::Blob.create_and_upload!(io: csv, filename: 'currencies.csv'))
        else
          currency_iso_code_attribute = country_feature.options.detect {|o| o.name == 'currency_iso_code_attribute'}.value
          import = Dynamic::Import::Setting.create!(
            name: IMPORT_NAME,
            schema: currency_schema_klass.schema,
            actor: User.current,
            async: true,
            visible: false,
            sources_attributes: [
              {
                klass_name: currency_schema_klass.const_absolute_name,
                csv: ActiveStorage::Blob.create_and_upload!(io: csv, filename: 'currencies.csv'),
                type: 'Dynamic::Import::Source::Csv',
                has_title_line: true,
                column_delimiter: ';',
                encoding: 'UTF-8',
                columns_attributes: columns_for_import(currency_schema_klass, currency_iso_code_attribute.name, currency_assoc.name),
                cascades_attributes: [
                  {
                    klass_name: currency_schema_klass.const_absolute_name,
                    keys: [
                      ['iso_code'],
                    ]
                  },
                  {
                    klass_name: currency_schema_klass.const_absolute_name,
                    assoc_id: currency_assoc.id,
                    keys: [
                      [currency_iso_code_attribute.name]
                    ]
                  }
                ],
              }
            ],
          )
        end

        job = import.create_init_job
        country_import = Dynamic::Import::Setting.find_by(name: Country::Feature::IMPORT_NAME, schema_id: feature.schema_id)
        if country_import && country_import.jobs.last&.pending? || country_import.jobs.last&.in_progress?
          if country_import.jobs.last.is_a?(Dynamic::Import::Job::Init)
            job_to_append = country_import.jobs.last
          else
            job_to_append = country_import.jobs.last.parent
          end
          job.update!(process_automatically: true)
          job_to_append.children << job # Will process "job" when "job_to_append" will be finished
        end
      end

      def self.after_enabled_and_commit_schema(feature)
        klass = feature.schema.klasses.detect {|k| k.name == 'Currency'}
        unless klass.name_attribute_id
          klass.update!(name_attribute_id: klass.attrs.detect {|a| a.name == 'name'}&.id)
        end
        update_currencies = feature.options.detect {|o| o.name == 'update_currencies'}
        if update_currencies&.value
          import = Dynamic::Import::Setting.find_by(name: IMPORT_NAME, schema_id: feature.schema_id)
          job = import.jobs.last
          job.process_async unless job.parent
          update_currencies.update!(value: false)
        end
      end

      def self.create_attributes(klass)
        attrs = []
        attrs << {
          name: 'iso_code',
          human_name_fr: 'Code iso',
          human_name_en: 'Iso code',
          type: 'String',
        } unless klass.attrs.where(name: 'iso_code').exists?

        attrs << {
          name: 'name',
          human_name_fr: 'Nom',
          human_name_en: 'Name',
          type: 'String',
        } unless klass.attrs.where(name: 'name').exists?

        attrs << {
          name: 'priority',
          human_name_fr: 'Priorité',
          human_name_en: 'Priority',
          type: 'Integer',
        } unless klass.attrs.where(name: 'priority').exists?

        attrs << {
          name: 'exponent',
          human_name_fr: 'Exposant',
          human_name_en: 'Exponent',
          type: 'Integer',
        } unless klass.attrs.where(name: 'exponent').exists?

        attrs << {
          name: 'symbol',
          human_name_fr: 'Symbole',
          human_name_en: 'Symbol',
          type: 'String',
        } unless klass.attrs.where(name: 'symbol').exists?

        attrs << {
          name: 'disambiguate_symbol',
          human_name_fr: 'Symbole désambigu',
          human_name_en: 'Disambiguate symbol',
          type: 'String',
        } unless klass.attrs.where(name: 'disambiguate_symbol').exists?

        attrs << {
          name: 'symbol_first',
          human_name_fr: 'Symbole en premier',
          human_name_en: 'Symbol first',
          type: 'Boolean',
        } unless klass.attrs.where(name: 'symbol_first').exists?

        attrs << {
          name: 'html_entity',
          human_name_fr: 'Entité HTML',
          human_name_en: 'HTML entity',
          type: 'String',
        } unless klass.attrs.where(name: 'html_entity').exists?

        attrs << {
          name: 'subunit',
          human_name_fr: 'Sous-unité',
          human_name_en: 'Subunit',
          type: 'String',
        } unless klass.attrs.where(name: 'subunit').exists?

        attrs << {
          name: 'subunit_to_unit',
          human_name_fr: 'Sous-unité par untié',
          human_name_en: 'Subunit to unit',
          type: 'Integer',
        } unless klass.attrs.where(name: 'subunit_to_unit').exists?

        attrs << {
          name: 'decimal_mark',
          human_name_fr: 'Separateur décimal',
          human_name_en: 'Decimal separator',
          type: 'String',
        } unless klass.attrs.where(name: 'decimal_mark').exists?

        attrs << {
          name: 'thousand_separator',
          human_name_fr: 'Séparateur des milliers',
          human_name_en: 'Thousand separator',
          type: 'String',
        } unless klass.attrs.where(name: 'thousand_separator').exists?

        attrs << {
          name: 'smallest_denomination',
          human_name_fr: 'Plus petite unité',
          human_name_en: 'Smallest denomination',
          type: 'Integer',
        } unless klass.attrs.where(name: 'smallest_denomination').exists?

        klass.attrs.create!(attrs) unless attrs.empty?
      end

      def self.create_associations(currency_schema_klass, country_schema_klass, feature)
        currency_has_many = currency_schema_klass.associations.create_with(
          human_name_fr: 'Pays',
          human_name_en: 'Countries',
          skip_create_default_forms: true,
        ).find_or_create_by(
          name: 'countries',
          type: 'HasMany',
          target_klass: country_schema_klass,
        )

        country_has_many = country_schema_klass.associations.create_with(
          human_name_fr: "Devises",
          human_name_en: 'Currencies',
          skip_create_default_forms: true,
        ).find_or_create_by(
          name: 'currencies',
          type: 'HasMany',
          target_klass: currency_schema_klass,
          inverse_of: currency_has_many,
        )

        currency_has_many.update(inverse_of: country_has_many)

        return currency_has_many
      end

      def self.columns_for_import(schema_klass, deduplication_key, country_assoc_name)
        result = []
        ATTRIBUTES.each_with_index do |h, i|
          next unless schema_klass.attrs.detect {|a| a.name == h}
          result << { position: i, path: [0, h] }
        end
        result << { position: result.dig(-1, :position) + 1, path: [0, country_assoc_name, 0, deduplication_key] }
        return result
      end

      def self.create_csv_to_import
        file = Tempfile.create('currencies.csv')
        CSV.open(file, 'w', write_headers: true, col_sep: ';', headers: ATTRIBUTES) do |csv|
          ::Money::Currency.all.each do |c|
            csv << [
              c.iso_code,
              c.name,
              c.priority,
              c.exponent,
              c.symbol,
              c.disambiguate_symbol,
              c.html_entity,
              c.symbol_first,
              c.subunit,
              c.subunit_to_unit,
              c.thousands_separator,
              c.decimal_mark,
              c.smallest_denomination,
              c.iso_code,
            ]
          end
        end
        return file
      end

    end
  end
end
