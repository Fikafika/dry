module Dynamic

  module Import

    class Setting < Base
      class << self
        def api_path
          @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'import_settings'].join('/')
        end

        def exceptions_for_update
          ['output']
        end

        def model_name
          @model_name = ModelName.new(
            human_name: I18n.t('activerecord.models.dynamic/import/setting.one'),
            plural_human_name: I18n.t('activerecord.models.dynamic/import/setting.other'),
            route_key: 'imports',
          )
        end

        class ModelName
          attr_reader :route_key

          def initialize(**options)
            @human_name = options[:human_name]
            @plural_human_name = options[:plural_human_name]
            @route_key = options[:route_key]
          end

          def human(**options)
            if options[:count].nil? || options[:count] <= 1
              return @human_name
            else
              return @plural_human_name
            end
          end
        end
      end

      belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :import_settings

      has_many :sources, class_name: 'Dynamic::Import::Source::Base', foreign_key: :setting_id, inverse_of: :setting, accept_nested_attributes: true
      has_many :jobs, class_name: 'Dynamic::Import::Job::Base', foreign_key: :setting_id, inverse_of: :setting
      has_many :transformations, class_name: 'Dynamic::Import::Transformation::Base', foreign_key: :setting_id, inverse_of: :setting
      has_one :output, class_name: 'Dynamic::Import::Source::Base', foreign_key: :setting_id, inverse_of: :setting
      member_action :process_all, {
        http_method: :get,
      }
      member_action :run_cron, {
        http_method: :get,
      }
      member_action :find_cron, {
        http_method: :get,
      }
      member_action :disable_cron, {
        http_method: :get,
      }
      member_action :enable_cron, {
        http_method: :get,
      }
      member_action :show_status_cron, {
        http_method: :get,
      }
      member_action :enqueue_cron, {
        http_method: :get,
      }
      member_action :destroy_cron, {
        http_method: :get,
      }
      member_action :duplicate, {
        http_method: :post,
      }

      scope :for_klass

      def init_jobs
        jobs.select{|j| j.type == 'Dynamic::Import::Job::Init'}.sort_by{|j| j.created_at || 0} # TODO should be sort_by id (why uuid are not sortable ?)
      end

      def self.exceptions_for_update
        [:output_attributes]
      end
    end

    module Source
      class Base < ::Dynamic::Base
        class << self
          def api_path
            @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'import_settings', ':setting_id', 'sources'].join('/')
          end

          def exceptions_for_update
            ['first_lines', 'title_line']
          end
        end

        has_many :columns, class_name: 'Dynamic::Import::Column', foreign_key: :source_id, inverse_of: :source, accept_nested_attributes: true

        has_many :cascades, class_name: 'Dynamic::Cascade', accept_nested_attributes: true

        belongs_to :setting, class_name: 'Dynamic::Import::Setting', inverse_of: :sources

        has_many :transformations, class_name: 'Dynamic::Import::Transformation::Base', foreign_key: 'input_id', inverse_of: :input, accept_nested_attributes: true
        has_one :transformation, class_name: 'Dynamic::Import::Transformation::Base', foreign_key: 'output_id', inverse_of: :output

        member_action :create_row, {
          http_method: :post,
        }

        member_action :create_column, {
          http_method: :post,
        }
      end
      class Csv < Base
        has_one_attached :csv
        has_one_attached :original_csv
      end
    end

    class Column < ::Dynamic::Base
      belongs_to :source, class_name: 'Dynamic::Import::Source::Base', inverse_of: :columns
    end
    module Transformation
      class Base < ::Dynamic::Base
        def api_path
          @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'import_settings', ':setting_id', 'sources', ':input_id', 'transformations'].join('/')
        end
        belongs_to :input, class_name: 'Dynamic::Import::Source::Base', inverse_of: :transformations
        belongs_to :output, class_name: 'Dynamic::Import::Source::Base', inverse_of: :transformation, accepts_nested_attributes: true
        belongs_to :setting, class_name: 'Dynamic::Import::Setting', inverse_of: :transformations

        def self.subclasses_by_type
          {
            transform: [
              SplitCell,
              CreateColumn,
            ],
            encoding: [
               Encoder,
               WindowsToUnixEndOfLine,
               MacToUnixEndOfLine,
               EscapeQuote,
            ]
          }
        end

        def self.attributes_for_new_instance
          {type: self.name}
        end
      end
      class SplitCell < Base
        def self.attributes_for_new_instance
          { type: self.name, columns: [{column: 'A', row_delimiters: ''}] }
        end
      end
      class CreateColumn < Base
        def self.attributes_for_new_instance
          { type: self.name, columns: [{new_col_name: '', formula: ''}] }
        end
      end
      class Encoder < Base
      end
      class WindowsToUnixEndOfLine < Base
      end
      class MacToUnixEndOfLine < Base
      end
      class EscapeQuote < Base
      end
    end

    module Job
      class Base < ::Dynamic::Base
        class << self
          def api_path
            @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'import_settings', ':setting_id', 'jobs'].join('/')
          end
        end
        belongs_to :schema, class_name: 'Dynamic::Schema'
        belongs_to :setting, class_name: 'Dynamic::Import::Setting', inverse_of: :jobs
        belongs_to :source, class_name: 'Dynamic::Import::Source::Base', foreign_key: 'source_id'
        has_many :logs, class_name: 'Dynamic::Import::Log::Base', foreign_key: :job_id, inverse_of: :job

        belongs_to :parent, class_name: 'Dynamic::Import::Job::Base', inverse_of: :children, optional: true
        has_many :children, class_name: 'Dynamic::Import::Job::Base', foreign_key: :parent_id, inverse_of: :parent
      end

      class Init < Base
      end
      class ImportFile < Base
      end

      module Reloading
        def reload
          Log::Base.cache[:all].keys.each do |k|
            Log::Base.cache[:all][k]&.stale!
          end
          super
        end
      end; Base.prepend(Reloading) unless Base < Reloading
    end

    module Log
      class Base < ::Dynamic::Base
        class << self
          def api_path
            @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'import_settings', ':setting_id', 'jobs', ':job_id', 'logs'].join('/')
          end
        end
        belongs_to :setting, class_name: '::Dynamic::Import::Setting'
        belongs_to :job, inverse_of: :logs, class_name: 'Dynamic::Import::Job::Base'
      end
    end

    module Worker
      class Base < ::Dynamic::Base
      end
      class Job < Base
      end
    end

  end

end
