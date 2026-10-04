class Crm
  class SelectSchema < Base
    include CrmLayout

    render{ content }

    def content
      DIV do
        global_toolbar
        DIV(class: "toolbar-offset-top pt-2") do
          if user.connected?
            DIV(class: 'd-flex align-items-center justify-content-center m-3') do
              case user.communities.length
              when 0
                user_is_not_in_a_community
              when 1
                Redirect("/crm/#{user.communities.first.permalink}")
              else
                schema_links
              end
            end
          end
        end
      end
    end

    def user_is_not_in_a_community
      DIV(class: 'alert alert-warning') do
        I18n.t('crm.user_is_not_in_a_community', user: "#{user.first_name} #{user.last_name}")
      end
    end

    def schema_links
      DIV(class: 'list-group') do
        user.communities.each do |community|
          Link("/crm/#{community.permalink}", class: 'list-group-item list-group-item-action') do
            community.name
          end
        end
      end
    end

    def user
      observe ::User.current
    end

  end
end
