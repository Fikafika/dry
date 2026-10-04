class PublicPage < HyperComponent
  include Hyperstack::Router::Helpers
  include ::Router::Resources

  render(DIV) do
    routes
  end

  def user
    observe User.current
  end

  before_mount do
    user
  end

  after_update do
    user
  end

  def routes
    Route("/", exact: true) do |match|
      with_authentication do
        if user.connected?
          Redirect('/crm')
        end
      end
    end
  end

end
