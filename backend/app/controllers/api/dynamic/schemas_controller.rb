class Api::Dynamic::SchemasController < Api::Dynamic::BaseController

  around_action :sidekiq_throttle_admin
  around_action :skip_unknown_attributes, only: [:create, :update]

  def count_records
    render json: cached_records_count, status: :ok
  end

  private

  def find_element
    @element = find_by_id_or_name(scope, params[:id], :classify_permalink)
  end

  def fetch_records_count
    find_element
    result = {}
    @element.klasses.map do |k|
      result[k.name] = k.count_records
    end
    return result
  end

  concerning :Cache do

    def cached_records_count
      if cache_enabled?
        Rails.cache.fetch("records_count-#{records_count_cache_key}", skip_nil: true, expires_in: 1.minute) do
          fetch_records_count
        end
      else
        fetch_records_count
      end
    end

    def cache_enabled?
      true
    end

    def records_count_cache_key
      params[:id]
    end

  end

  concerning :Authentication do

    def authenticate_before_find_element?
      action_name != 'show'
    end

    def authenticate_after_find_element?
      action_name != 'show'
    end

  end

  concerning :Authorization do

    def skip_permissions?
      current_user_is_admin?
    end

    def check_permissions
      unless action_name.in?(['index', 'show']) || @element.nil?
        raise UneekPermission::UnauthorizedAction, "You can not access schema #{@element.name}"
      end
    end

  end

end
