Rails.application.routes.draw do

  uuid = /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/

  scope(ENV['APP_PATH_PREFIX']) do

    namespace :api do
      devise_for :users, singular: :user, controllers: { cas_sessions: 'devise/cas_sessions' }
      get 'user', to: 'users#current'

      resources :communities
      resources :users
      resources :roles
      resources :role_context_fields

      namespace :dynamic do
        resources :schemas do
          member do
            get :count_records
          end
          resources :klasses, controller: 'schema/klasses' do
            member do
              post :reindex
            end

            resources :attributes, controller: 'schema/klass/attributes' do
              resources :values, controller: 'schema/klass/attribute/values'
              resources :sequences, controller: 'schema/klass/attribute/sequences'
              resources :normalizations, controller: 'schema/klass/attribute/normalizations'
              member do
                post :recompute_formula
              end
            end
            resources :associations, controller: 'schema/klass/associations' do
              member do
                post :recompute_formula
              end
            end
            resources :attachments, controller: 'schema/klass/attachments' do
              resources :variants, controller: 'schema/klass/attachment/variants'
            end
            resources :validations, controller: 'schema/klass/validations'

            namespace :doc_gen do
              resources :templates, controller: '/api/dynamic/schema/reserved/doc_gen/templates' do
                resources :files, controller: '/api/dynamic/schema/reserved/doc_gen/merge/files'
                resources :generations, only: [:create], controller: '/api/dynamic/schema/reserved/doc_gen/generations'
              end
            end
          end

          resources :features, controller: 'schema/features' do
            resources :concerns, controller: 'schema/feature/concerns'
          end

          resources :migrations, controller: 'schema/migrations'

          resources :cascades, controller: 'schema/cascades'

          resources :forms, controller: 'schema/forms' do
            member do
              post :submit
              post :save_as_draft
              post :submit_all
              post :duplicate
            end
          end
          resources :form_submissions, controller: 'schema/form/submissions' do
            collection do
              get :count
            end
          end

          resources :layouts, controller: 'schema/layouts' do
            resources :elements, controller: 'schema/layout/elements'
          end

          resources :import_settings, controller: 'schema/import/settings' do

            member do
              get :process_all
              get :run_cron
              get :find_cron
              get :disable_cron
              get :enable_cron
              get :show_status_cron
              get :enqueue_cron
              get :destroy_cron
              post :duplicate
            end

            resources :sources, controller: 'schema/import/sources'

            resources :jobs, controller: 'schema/import/jobs' do

              member do
                post :process
              end

              resources :logs, controller: 'schema/import/logs' do
              end
            end

          end

          resources :redirections, controller: 'schema/redirections'
        end
        resources :themes
      end

      get '/d/:schema_name/dynamic_associations', to: 'dynamic/record/associations#index' # /d/uneek/dynamic_associations.json
      get '/d/:schema_name/dynamic_associations/new', to: 'dynamic/record/associations#new'
      get '/d/:schema_name/dynamic_associations/count', to: 'dynamic/record/associations#count'
      patch '/d/:schema_name/dynamic_associations', to: 'dynamic/record/associations#update_all'
      delete '/d/:schema_name/dynamic_associations', to: 'dynamic/record/associations#destroy_all'
      put '/d/:schema_name/dynamic_associations/:id', to: 'dynamic/record/associations#update', constraints: {id: uuid}
      patch '/d/:schema_name/dynamic_associations/:id', to: 'dynamic/record/associations#update', constraints: {id: uuid}
      delete '/d/:schema_name/dynamic_associations/:id', to: 'dynamic/record/associations#destroy', constraints: {id: uuid}

      get '/d/:schema_name/:klass_name/:id/versions', to: 'dynamic/record/versions#index' # /d/uneek/contact/1/versions.json

      get '/d/:schema_name/:klass_name/new', to: 'dynamic/record/base#new'
      get '/d/:schema_name/:klass_name/:id', to: 'dynamic/record/base#show', constraints: {id: uuid} # /d/uneek/contacts/1.json
      get '/d/:schema_name/:klass_name', to: 'dynamic/record/base#index' # /d/uneek/contacts.json
      post '/d/:schema_name/:klass_name', to: 'dynamic/record/base#create'
      patch '/d/:schema_name/:klass_name', to: 'dynamic/record/base#update_all'
      delete '/d/:schema_name/:klass_name', to: 'dynamic/record/base#destroy_all'
      put '/d/:schema_name/:klass_name/:id', to: 'dynamic/record/base#update', constraints: {id: uuid}
      patch '/d/:schema_name/:klass_name/:id', to: 'dynamic/record/base#update', constraints: {id: uuid}
      delete '/d/:schema_name/:klass_name/:id', to: 'dynamic/record/base#destroy', constraints: {id: uuid}

      get '/d/:schema_name/:klass_name/count', to: 'dynamic/record/base#count' # /d/uneek/contacts/count.json
      post '/d/:schema_name/:klass_name/find_or_create_by', to: 'dynamic/record/base#find_or_create_by'
      post '/d/:schema_name/:klass_name/import', to: 'dynamic/record/base#import'
      patch '/d/:schema_name/:klass_name/update_positions', to: 'dynamic/record/base#update_positions'

      post '/d/:schema_name/:klass_name/data', to: 'dynamic/record/base#data' # /d/uneek/contacts/data.json
      post '/d/:schema_name/:klass_name/dashboard', to: 'dynamic/record/base#dashboard' # /d/uneek/contacts/dashboard.json
      post '/d/:schema_name/:klass_name/datatable', to: 'dynamic/record/base#datatable' # /d/uneek/contacts/datatable.json

      get '/search/d/:schema_name', to: 'dynamic/record/base#index'
      get '/variables/d/:schema_name', to: 'variables#index'
      get '/search', to: 'search#index'
      get '/mime_types', to: 'mime_types#index'

      mount Dynamic::Workflow::Engine => "/workflow/:community_id"
      mount ::FormulaLanguageServer.server => '/lsp/d/:schema_name/:klass_name'
      mount Dynamo::Cd83::Api::Engine => "/cd83"
      mount UneekPermission::Engine => "/uneek_permission"
      mount UneekSsoClient::Engine, at: '/uneek_sso_client', as: 'uneek_sso_client_api'
    end

    get '/api', to: 'api/root#ping'
    get '/api/d/r__apis', to: 'api/dynamic/api/base#index'
  end

end
