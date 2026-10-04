ActiveSupport.on_load(:dynamic_layout) do
  include MassAssignmentSkipUnknownAttributes

  scope :for_menu_item, -> (menu_item_id) { where(menu_item_id: [nil, menu_item_id]) }


  concerning :Export do

    class_methods do

      def includes_for_export(export_options = {})
        return {
          except: export_include_exceptions(self),
          include: {
            translations: {
              as: :translations_attributes,
              except: export_include_exceptions + ['dynamic_layout_id'],
            },
            elements: {
              as: :elements_attributes,
              except: export_include_exceptions(Dynamic::Layout::Element),
            },
          }
        }
      end

      def export_include_exceptions(klass = nil)
        r = ['created_at', 'updated_at', 'deleted_at', 'schema_id']
        r += ['layout_id'] unless klass == self
        return r
      end

    end

  end

end
