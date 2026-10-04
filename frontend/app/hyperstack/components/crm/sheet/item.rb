class Crm
  class Sheet

    class Item < ::Crm::List::Item

      param :purpose, default: 'sheet'

      class ParamsConverter < ::Layout::ParamsConverter
        converter_for 'Crm::Sheet::Item'
        def apply(params, options = {})
          {
            record: options[:delegate_params][:record].association_target,
            association: options[:delegate_params][:record],
          }
        end
      end

      class EditIconParamsConverter < ::Layout::ParamsConverter
        include ::Crm::Routes::Helpers
        converter_for 'IconButton'

        def request
          App.request
        end

        def apply(params, options = {})
          result = {
            icon: 'arrow-up-right-from-square',
            variant: 'transparent-light-yiq',
            data: {'open-panel': 'opposite'},
            shape: '',
          }
          record = options[:delegate_params][:record].association_target
          result[:target] = edit_url(record.class, record.id) if record
          return result
        end
      end

      class Menu < ::Crm::Sheet::Menu

        param :association, default: nil

        render { content }

        def menu_items
          edit_link
          if record && record.class.respond_to?(:menu_items)
            block = record.class.menu_items(record)
            instance_exec(&block)
          end
          delete_record_link
          delete_association_link(association) if association
        end

        def menu_id
          other_params[:id] || "item-menu"
        end

        def edit_link
          return unless record
          A(href: edit_url(record.class, record.id), class: 'dropdown-item', 'data-open-panel': 'opposite') do
            I18n.t('shared.edit')
          end
        end

        def delete_success
          self.jq_node.trigger('reload.crm.sheet')
          self.jq_node.trigger('reload.crm.index')
        end

        def delete_association_link
          A(href: '#', class: 'dropdown-item') do
            I18n.t('crm.sheet.delete_association')
          end.on(:click) do |event|
            event.prevent_default
            Modal.confirm(title: I18n.t('crm.sheet.delete_association')) do
              association.destroy(wait_for_completed_jobs_options).then do |response|
                if response[:success]
                  delete_success
                end
              end
            end
          end
        end

        class ParamsConverter < ::Layout::ParamsConverter
          converter_for 'Crm::Sheet::Item::Menu'
          def apply(params, options = {})
            {
              record: options[:delegate_params][:record].association_target,
              association: options[:delegate_params][:record],
            }
          end
        end

      end

    end

  end
end
