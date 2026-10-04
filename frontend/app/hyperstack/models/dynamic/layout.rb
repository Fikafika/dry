module Dynamic
  class Layout < Base

    scope :with_deleted
    scope :with_action
    scope :for_menu_item

    ACTIONS = ['index', 'new', 'edit', 'show']

    def self.actions
      ACTIONS
    end

    def persisted=(v)
      @persisted = v
    end

    def persisted?
      return @persisted unless @persisted.nil?
      return super
    end

    class << self
      def api_path
        @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'layouts'].join('/')
      end

      def load(schema_id, mode, purpose, record_or_klass_or_klass_name)
        case record_or_klass_or_klass_name
        when ::Class
          klass_name = record_or_klass_or_klass_name.name
        when ::String
          klass_name = record_or_klass_or_klass_name
        when ::HyperResource::Base
          klass_name = record_or_klass_or_klass_name.class.name
        end
        return nil unless klass_name
        return self.with_action(mode)
          .where(schema_id: schema_id, klass_name: klass_name, purpose: purpose)
          .nilify_blanks(:purpose)
          .includes(includes_for_load)
          .first
      end

      def includes_for_load
        {
          except: [
            'updated_when_schema_is_changed',
          ],
          include: {
            translations: { except: ['schema_id', 'dynamic_layout_id'] },
            elements: {
              except: [
                'created_at',
                'updated_at',
                'schema_id',
                'layout_id',
              ],
            },
          }
        }
      end

    end

    translates :human_name
    globalize_accessors

    belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :layouts
    has_many :elements, class_name: 'Dynamic::Layout::Element', inverse_of: :layout

    def root_elements
      elements_by_parent_id[nil]
    end

    def elements_by_id
      return @elements_by_id if @elements_by_id && loaded?
      @elements_by_id ||= {}
      elements.each do |e|
        @elements_by_id[e.id] = e
      end
      return @elements_by_id
    end

    def elements_by_parent_id
      return @elements_by_parent_id if @elements_by_parent_id && loaded?
      @elements_by_parent_id ||= {nil => []}
      elements.each do |e|
        @elements_by_parent_id[e.id] ||= []
        @elements_by_parent_id[e.parent_id] ||= []
        @elements_by_parent_id[e.parent_id] << e
      end
      return @elements_by_parent_id
    end

    def reload
      @elements_by_parent_id = nil
      @elements_by_id = nil
      super
    end

    def duplicate(base_attrs = {})
      attrs = base_attrs.dup
      attrs[:elements_attributes] = self.elements.map do |e|
        a = e.attributes.except('id', 'created_at', 'updated_at', 'deleted_at')
        a[:duplicate_related_records] = true
        a
      end

      attrs[:actions] ||= self.actions

      Dynamic::Layout
        .where(schema_id: self.schema_id, klass_name: self.klass_name, purpose: self.purpose)
        .includes(Dynamic::Layout.includes_for_load)
        .create(
        attrs
      ) do |r|
        yield if block_given?
      end
    end

    class Base < ::Dynamic::Base; end
    class Element < Base

      def self.api_path
        @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'layouts', ':layout_id', 'elements'].join('/')
      end

      belongs_to :layout, class_name: 'Dynamic::Layout', inverse_of: :elements

      def persisted=(v)
        @persisted = v
      end

      def persisted?
        return @persisted unless @persisted.nil?
        return super
      end

      def parent
        raise 'layout not loaded' unless layout&.loaded?
        layout.elements_by_id[self.parent_id]
      end

      def children
        raise 'layout not loaded' unless layout&.loaded?
        result = layout.elements_by_parent_id[self.id]
        unless result
          result = layout.elements_by_parent_id[self.id] = []
        end
        return result
      end

      def ancestors
        raise 'layout not loaded' unless layout&.loaded?
        result = Set.new
        e = self
        while e && e.parent_id
          e = layout.elements_by_id[e.parent_id]
          result << e if e
        end
        return result.to_a
      end

      def descendants(result = Set.new)
        children.each do |c|
          next if result.include?(c)
          result << c
          c.descendants(result)
        end
        return result.to_a
      end

      def component_params_converter
        return unless component_params_converter_type
        @component_params_converter ||= component_params_converter_type.constantize
        return @component_params_converter
      end

    end
  end
end
