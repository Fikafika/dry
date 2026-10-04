class Settings

  class Recents < Base
    include Hyperstack::Router::Helpers

    render { content }

    module Concern; extend ActiveSupport::Concern

      def content
        layout(2) do
          parent_page(col: "col-sm-6 d-flex")
          recents_page
        end
      end

      def recents_page
        ::Stackable::Page(col: "col-sm-6 d-none d-sm-flex") do
          ::Stackable::Toolbar() do
            ::Stackable::PageHeader(title: I18n.t('crm.settings'))
          end
          DIV(class: 'p-2 h-100 overflow-auto') do
            recents
          end
        end
      end

      def recents
        return unless self.class.entries.any?
        DIV(class: 'h-100 w-100') do
          DIV(class: 'text-center') do
            I18n.t('settings.frequently_used')
          end
          DIV(class: 'grid-fluid grid-fluid-4 grid-gap-1') do
            self.class.entries[0..7].each do |r|
              Link(r[:path], class: 'btn btn-transparent-light-yiq shadow-none') do
                DIV(class: "text-center") do
                  I(class: "fa fa-#{r[:icon]} mr-1 fa-3x w-100")
                  SPAN do
                    r[:title]
                  end
                end
              end
            end
          end
        end
      end

      class_methods do
        def add_entry(entry)
          @entries ||= {}
          @entries[entry] ||= 0
          @entries[entry] += 1
        end

        def entries
          @entries ||= {}
          @entries.sort_by {|k, v| v}.reverse.map(&:first)
        end
      end

    end

    include Concern

  end

end

