module Dynamic
  module Query
    class Base < ActiveRecord::Base
      self.abstract_class = true
      self.store_full_sti_class = false

      validates_presence_of :type

      def attributes_protected_by_default # redefined for mass assign type (validation in subclasses doesn't work with this hack)
        super - [self.class.inheritance_column]
      end

      def self.sti_name
        @sti_name ||= self.name.gsub(/.*::Query::/, '')
      end

      include Dynamic::Mount

      define_table do |t|
        t.string :human_name, translate: true
        t.string :path
        t.uuid :user_id, index: true
        t.json :params
        t.uuid :original_id
        t.string :type, index: true
      end

      def copy_to_users(users)
        user_ids = users.map(&:id)
        attrs = {
          path: self.path,
          params: self.params,
        }
        I18n.available_locales.each do |l|
          localized = :"human_name_#{l}"
          attrs[localized] = self.send(localized)
        end
        queries_attrs = []
        user_ids.each do |user_id|
          queries_attrs << attrs.merge(user_id: user_id)
        end
        self.class.create!(queries_attrs)
      end

      def self.name_attribute
        :human_name
      end
    end

    class Saved < Base; end
    class Current < Base; end

    module Feature; extend Dynamic::Feature

      def self.feature_attributes
        {
          human_name_fr: 'Requête enregistrées',
          human_name_en: 'Saved queries',
          mandatory: true,
          visible: false,
          options_attributes: [
            {
              name: 'elasticsearch_indices_already_created',
              human_name_en: 'Elasticsearch indices already created',
              human_name_fr: "Creation des index elasticsearch effectuée",
              type: 'Boolean',
              value: false
            },
          ],
        }
      end

      def self.load(schema)
        base = ::Dynamic::Query::Base.mount(schema)
        base.belongs_to :original, class_name: "D::#{schema.name}::R::Query::Base", optional: true

        base.module_parent.const_set(:Current, Class.new(base))

        base.module_parent.const_set(:Saved, Class.new(base))

        if schema.feature_enabled?('Dynamic::Elasticsearch::Feature')
          saved = base.module_parent::Saved
          saved.class_eval { def self.global_search_fields; ["human_name"]; end}
          saved.define_method(:as_indexed_json) do |*args|
            as_json(only: ['id', 'type', 'human_name', 'human_name_fr', 'human_name_en', 'deleted_at'])
          end

          feature = schema.features.detect{|e| e.name == self.name}
          Dynamic::Elasticsearch::Feature.include_opensearch_model(saved, feature)
        end
        return true
      end

    end

  end

end
