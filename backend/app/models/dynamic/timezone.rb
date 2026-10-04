module Dynamic
  module Timezone
    module Feature; extend Dynamic::Feature

      ATTRIBUTES = [
        'country_code_iso',
        'country_label',
        'tz_id',
        'description',
        'longitude',
        'latitude',
      ].freeze

      DEPENDENCIES = ['Dynamic::Country::Feature'].freeze
      REVERSE_DEPENDENCIES = ['Dynamic::PhoneData::Feature'].freeze

      IMPORT_NAME = 'From Dynamic Feature : Timezones'.freeze

      def self.feature_attributes
        {
          # no dependency
          human_name_fr: 'Fuseaux horraire',
          human_name_en: 'Timezone',
          mandatory: false,
          enabled: false,
        }
      end

      def self.after_disabled(feature)
        dependency = feature.schema.features.find_by!(name: REVERSE_DEPENDENCIES[0])
        if dependency
          has_reverse_dependency_phone_category = feature.concerns.detect {|c| c.options.detect {|o| o.name == 'timezone_association'}&.value }
          dependency.update(enabled: false) if has_reverse_dependency_phone_category
        end
      end

      def self.after_enabled(feature)
        DEPENDENCIES.each do |d|
          dependency = feature.schema.features.find_by!(name: d)
          unless dependency.enabled
            feature.errors.add :enabled, :dependent, name: dependency.human_name
            raise ActiveRecord::RecordInvalid.new(feature)
          end
        end

        timezone_schema_klass = feature.schema.klasses.create_with(
          human_name_fr: 'Fuseaux Horraire',
          human_name_en: 'Timezone',
          plural_human_name_fr: 'Fuseaux Horraires',
          plural_human_name_en: 'Timezones',
          icon: 'clock',
          skip_create_default_forms: [:new],
          table_profile: :small,
        ).find_or_create_by!(name: 'Timezone')

        country_schema_klass = feature.schema.klasses.find_by!(name: 'Country')

        name_attribute = self.create_attributes(timezone_schema_klass, feature)
        timezone_schema_klass.update!(name_attribute_id: name_attribute.id)

        timezone_assoc = self.create_associations(timezone_schema_klass, country_schema_klass, feature)

        csv = create_csv_to_import
        import = Dynamic::Import::Setting.find_by(name: IMPORT_NAME, schema_id: feature.schema_id)
        if import
          import.sources.first.csv.attach(ActiveStorage::Blob.create_and_upload!(io: csv, filename: 'timezones.csv'))
        else
          import = Dynamic::Import::Setting.create!(
            name: IMPORT_NAME,
            schema: timezone_schema_klass.schema,
            actor: User.current,
            async: true,
            visible: false,
            sources_attributes: [
              {
                klass_name: timezone_schema_klass.const_absolute_name,
                csv: ActiveStorage::Blob.create_and_upload!(io: csv, filename: 'timezones.csv'),
                type: 'Dynamic::Import::Source::Csv',
                has_title_line: true,
                column_delimiter: ';',
                encoding: 'UTF-8',
                columns_attributes: columns_for_import(timezone_schema_klass),
                cascades_attributes: [
                  {
                    klass_name: timezone_schema_klass.const_absolute_name,
                    keys: [
                      ['tz_id'],
                    ]
                  },
                  {
                    klass_name: timezone_schema_klass.const_absolute_name,
                    assoc_id: timezone_assoc.id,
                    keys: [
                      ['iso_code_a2']
                    ]
                  }
                ],
              }
            ],
          )
        end

        job = import.create_init_job
        country_import = Dynamic::Import::Setting.find_by(name: Country::Feature::IMPORT_NAME, schema_id: feature.schema_id)
        if country_import && country_import.jobs.last.pending? || country_import.jobs.last.in_progress?
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
        import = Dynamic::Import::Setting.find_by(name: IMPORT_NAME, schema_id: feature.schema_id)
        job = import.jobs.last
        job.process_async unless job.parent
      end

      def self.create_csv_to_import
        file = Tempfile.create('timezones.csv')
        CSV.open(file, 'w', write_headers: true, col_sep: ';', headers: ATTRIBUTES) do |csv|
          ::TZInfo::Country.all.each do |c|
            c.zone_info.each do |zi|
              csv << [
                c.code,
                c.name,
                zi.identifier,
                zi.description,
                zi.longitude,
                zi.latitude,
              ]
            end
          end
        end
        return file
      end

      def self.columns_for_import(schema_klass)
        result = [
          { position: 0, path: [0, 'countries', 0, 'iso_code_a2'] },
          { position: 1, path: [0, 'countries', 0, 'name'], when_update: false }
        ]
        ATTRIBUTES.each_with_index do |h, i|
          next unless schema_klass.attrs.detect {|a| a.name == h}
          result << { position: i, path: [0, h] }
        end
        return result
      end

      def self.create_associations(timezone_schema_klass, country_schema_klass, feature)
        timezone_has_many = timezone_schema_klass.associations.create_with(
          human_name_fr: 'Pays',
          human_name_en: 'Countries',
          skip_create_default_forms: true,
        ).find_or_create_by(
          name: 'countries',
          type: 'HasMany',
          target_klass: country_schema_klass,
        )

        country_has_many = country_schema_klass.associations.create_with(
          human_name_fr: 'Fuseaux',
          human_name_en: 'Timezones',
          skip_create_default_forms: true,
        ).find_or_create_by(
          name: 'timezones',
          type: 'HasMany',
          target_klass: timezone_schema_klass,
          inverse_of: timezone_has_many,
        )

        timezone_has_many.update(inverse_of: country_has_many)

        return timezone_has_many
      end

      def self.create_attributes(klass, feature)
        attrs = []
        attrs << {
          name: 'tz_id',
          human_name_fr: 'Identifiant fuseau',
          human_name_en: 'Timezone identifier',
          type: 'String',
        } unless klass.attrs.where(name: 'tz_id').exists?

        attrs << {
          name: 'description',
          human_name_fr: 'Description',
          human_name_en: 'Description',
          type: 'String',
        } unless klass.attrs.where(name: 'description').exists?

        attrs << {
          name: 'longitude',
          human_name_fr: 'Longitude',
          human_name_en: 'Longitude',
          type: 'Float',
        } unless klass.attrs.where(name: 'longitude').exists?

        attrs << {
          name: 'latitude',
          human_name_fr: 'Latitude',
          human_name_en: 'Latitude',
          type: 'Float',
        } unless klass.attrs.where(name: 'latitude').exists?

        klass.attrs.create!(attrs) unless attrs.empty?
        return klass.attrs.detect {|a| a.name == 'tz_id'}
      end

    end
  end
end
