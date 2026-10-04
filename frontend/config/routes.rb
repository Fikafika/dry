Rails.application.routes.draw do
  scope(ENV['APP_PATH_PREFIX']) do
    devise_for :users, path_prefix: "#{ENV['APP_PATH_PREFIX']}/api"

    get "/up", to: proc { [200, {}, ["ok"]] }, as: :rails_health_check

    mount Hyperstack::Engine => '/hyperstack'

    resource :js_error, only: [:create] do
      collection do
        post :original_position # post because backtrace is too long
      end
    end

    get '/themes/*other', to: proc { [404, {}, ['']] }
    get '/api/*other', to: proc { [404, {}, ['']] }  # managed by backend (prevent render layout and compile js when backend is not here)
    get '/(*other)', to: 'hyperstack#app', constraints: lambda { |request| !request.path&.start_with?("#{ENV['APP_PATH_PREFIX']}/assets/") }
  end
end
