class SignInModal < HyperComponent

  render { content }

  def content
    DIV() do
      DIV(modal_params) do
        DIV(class: 'modal-dialog modal-md') do
          DIV(class: 'modal-content') do
            DIV(class: 'modal-body text-center') do
              H4() do
                'Connexion'
              end
              I(class: 'fa fa-refresh fa-spin')
            end
          end
        end
      end
      render_children
    end
  end

  def render_children
    children.render
  end

  def modal_params
    { id: 'sign-in-modal', class: 'modal fade', role: 'dialog' }
  end

  class Required < SignInModal

    def user
      observe User.current
    end

    before_mount do
      user
    end

    after_mount do
      unless user.loading?
        after_render_callbacks
      end
    end

    before_unmount :close_modal

    before_update :close_modal

    render { content }

    def render_children
      super if user.connected?
    end

    after_update do
      after_render_callbacks
    end

    def after_render_callbacks
      if user.connected?
        user.show_sign_in_modal(false)
      else
        user.sign_in
      end
    end

    def modal_params
      super.merge('data-backdrop': 'static', 'data-keyboard': 'false')
    end

    def close_modal
      user.show_sign_in_modal(false)
    end

  end

  class Optional < HyperComponent

    before_mount do
      try_authenticate
    end

    render do
      if @tried
        children.render
      end
    end

    def try_authenticate
      `
        UneekSso.UserSessions._sendAjax("showModal", {
          type: "GET",
          url: UneekSso.UserSessions.getCasLoginUrl(),
          success: function (data, textStatus, xhr) {
            console.log('authenticated')
            #{ mutate @tried = true }
          },
          error: function(e) {
            console.log('not authenticated')
            #{ mutate @tried = true }
          }
        });
      `
    end

  end

end
