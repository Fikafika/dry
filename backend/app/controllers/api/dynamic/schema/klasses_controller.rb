class Api::Dynamic::Schema::KlassesController < Api::Dynamic::Schema::BaseController

  around_action :enable_notification

  def reindex
    find_element
    result = @element.try(:reindex_all_records_asynchronously)
    head :ok
  end

end
