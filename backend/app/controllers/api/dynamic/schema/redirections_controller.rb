class Api::Dynamic::Schema::RedirectionsController < Api::Dynamic::Schema::BaseController

  private

  def find_element
    @element = find_by_id_or_name(scope, params[:id], :underscore)
  end

  def klass
    Dynamic::Redirection
  end

  concerning :Authentication do

    def authenticate_before_find_element?
      action_name != 'show'
    end

  end

end
