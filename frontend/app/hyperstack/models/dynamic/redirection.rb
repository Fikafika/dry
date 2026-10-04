module Dynamic
  class Redirection < Base
    include ::HyperResource::EnumString

    class << self
      def api_path
        @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'redirections'].join('/')
      end

      def target_types
        [
          'Form',
          'Vcard',
        ]
      end

      def api_id(resource)
        resource.name
      end
    end

    belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :redirections
    belongs_to :klass, class_name: 'Dynamic::Schema::Klass', where: ->(r) { {schema_id: r.schema_id} }
    belongs_to :target_klass, class_name: 'Dynamic::Schema::Klass', where: ->(r) { {schema_id: r.schema_id} }
    belongs_to :fallback_klass, class_name: 'Dynamic::Schema::Klass', where: ->(r) { {schema_id: r.schema_id} }

    enum condition_type: [
      'Permission',
    ]

    enum target_type: target_types

    enum fallback_type: target_types

  end
end
