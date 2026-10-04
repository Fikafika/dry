module Dynamic
  module DocGen
    class Template < ::Dynamic::Base
      class << self
        def api_path
          @api_path ||= [::Dynamic::Schema.api_path, schema_name, 'klasses', ':klass_id', 'doc_gen', 'templates'].join('/')
        end

        def member_params_key
          'template'
        end

        def feature
          'Dynamic::DocGen::Feature'
        end

        def name_attribute
          'name'
        end
      end

      attribute :type, type: 'String'
      attribute :class_name, type: 'String'
      attribute :multiple, type: 'Boolean'

      translates :name
      globalize_accessors

      def possible_formats
        []
      end

      def json=(data)
        super
        if data['class_name']
          attributes['klass_id'] = data['class_name']&.demodulize&.underscore
        end
      end

      def klass
        self.class_name&.safe_constantize
      end
    end

    module Merge
      class File < ::Dynamic::Base
        class << self
          def api_path
            @api_path ||= [::Dynamic::Schema.api_path, schema_name, 'klasses', ':klass_id', 'doc_gen', 'templates', ':template_id', 'files'].join('/')
          end

          def member_params_key
            'file'
          end

          def feature
            'Dynamic::DocGen::Feature'
          end
        end

        def json=(data)
          class_name = data.dig('template', 'class_name')
          super
          if class_name
            attributes['klass_id'] = class_name.demodulize.underscore
          end
        end
        attribute :type, type: 'String'
      end
    end

    class Generation < ::Dynamic::Base
      class << self
        def api_path
          @api_path ||= [::Dynamic::Schema.api_path, schema_name, 'klasses', ':klass_id', 'doc_gen', 'templates', ':template_id', 'generations'].join('/')
        end

        def member_params_key
          'generation'
        end

        def feature
          'Dynamic::DocGen::Feature'
        end
      end

      def json=(data)
        super
        if data['class_name']
          attributes['klass_id'] = data['class_name']&.demodulize&.underscore
        end
      end

      belongs_to :record, polymorphic: true
      has_many :records, polymorphic: true

      has_one_attached :file
    end

    module Feature; extend ActiveSupport::Concern

      def self.load_constants(schema)
        template_klass = schema.const_reserved_klass("DocGen::Template", ::Dynamic::DocGen::Template)

        docx_template_klass = schema.const_reserved_klass("DocGen::DocxTemplate", template_klass) do |klass|
          klass.class_eval do
            has_one_attached :docx

            class << self
              def i18n_key
                'dynamic/doc_gen/docx_template'
              end
            end

            def possible_formats
              [:docx, :pdf]
            end
          end
        end
        docx_template_klass.instance_variable_set(:@attributes, template_klass.attributes.dup)

        wrapper_template_klass = schema.const_reserved_klass("DocGen::WrapperTemplate", template_klass) do |klass|
          klass.belongs_to(:wrapped_template, class_name: template_klass.name, inverse_of: :wrapper_templates)

          klass.class_eval do
            attribute :wrapped_format, type: 'String'

            class << self
              def i18n_key
                'dynamic/doc_gen/wrapper_template'
              end
            end

            def possible_formats
              self.wrapped_template&.possible_formats || super
            end
          end
        end
        wrapper_template_klass.instance_variable_set(:@attributes, template_klass.attributes.dup)
        template_klass.has_many(:wrapper_templates, class_name: wrapper_template_klass.name)

        # Merge
        merge_file_klass = schema.const_reserved_klass("DocGen::Merge::File", ::Dynamic::DocGen::Merge::File)
        merge_file_klass.instance_variable_set(:@attributes, ::Dynamic::DocGen::Merge::File.attributes.dup)
        merge_static_file_klass = schema.const_reserved_klass("DocGen::Merge::StaticFile", merge_file_klass) do |klass|
          klass.class_eval do
            has_one_attached :file

            class << self
              def i18n_key
                'dynamic/doc_gen/merge/static_file'
              end
            end

            def name
              self.file&.filename
            end
          end
        end
        merge_static_file_klass.instance_variable_set(:@attributes, merge_file_klass.attributes.dup)
        merge_attribute_file_klass = schema.const_reserved_klass("DocGen::Merge::AttributeFile", merge_file_klass) do |klass|
          klass.class_eval do
            attribute :attribute_path

            class << self
              def i18n_key
                'dynamic/doc_gen/merge/attribute_file'
              end
            end

            def name
              k = self.template.klass
              result = []
              self.attribute_path.each do |attr|
                result << k.human_attribute_name(attr)
                if reflection = k.reflect_on_association(attr)
                  k = reflection.klass
                end
              end
              result.join(' > ')
            end
          end
        end
        merge_attribute_file_klass.instance_variable_set(:@attributes, merge_file_klass.attributes.dup)
        merge_template_file_klass = schema.const_reserved_klass("DocGen::Merge::TemplateFile", merge_file_klass) do |klass|
          klass.belongs_to(:object_template, class_name: template_klass.name, inverse_of: :merge_template_files)

          klass.class_eval do
            class << self
              def i18n_key
                'dynamic/doc_gen/merge/template_file'
              end
            end

            def name
              self.object_template&.name
            end
          end
        end
        merge_template_file_klass.instance_variable_set(:@attributes, merge_file_klass.attributes.dup)

        merge_template_klass = schema.const_reserved_klass("DocGen::Merge::Template", template_klass) do |klass|
          klass.has_many(:files, class_name: merge_file_klass.name, inverse_of: :template)

          klass.class_eval do
            class << self
              def i18n_key
                'dynamic/doc_gen/merge/template'
              end
            end
          end
        end
        merge_template_klass.instance_variable_set(:@attributes, template_klass.attributes.dup)
        merge_file_klass.belongs_to(:template, class_name: merge_template_klass.name, inverse_of: :files)
        merge_pdf_template_klass = schema.const_reserved_klass("DocGen::Merge::PdfTemplate", merge_template_klass) do |klass|
          klass.class_eval do
            class << self
              def i18n_key
                'dynamic/doc_gen/merge/pdf_template'
              end
            end

            def possible_formats
              [:pdf]
            end
          end
        end
        merge_pdf_template_klass.instance_variable_set(:@attributes, merge_template_klass.attributes.dup)
        merge_zip_template_klass = schema.const_reserved_klass("DocGen::Merge::ZipTemplate", merge_template_klass) do |klass|
          klass.class_eval do
            class << self
              def i18n_key
                'dynamic/doc_gen/merge/zip_template'
              end
            end

            def possible_formats
              [:zip]
            end
          end
        end
        merge_zip_template_klass.instance_variable_set(:@attributes, merge_template_klass.attributes.dup)

        generation_klass = schema.const_reserved_klass("DocGen::Generation", ::Dynamic::DocGen::Generation) do |klass|
          klass.belongs_to(:template, class_name: template_klass.name)
        end
      end

    end
  end
end
