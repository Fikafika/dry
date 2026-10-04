class Api::Dynamic::Schema::Form::SubmissionsController < Api::Dynamic::Schema::Form::BaseController

  def find_element
    @element = scope.find(params[:id])
  end

  def scope
    super.where(submitter_id: User.current.id) # TODO permissions
  end

  def base_scope
    Dynamic::Form::Submission
  end

end
