class Api::Dynamic::Schema::Klass::Attribute::NormalizationsController < Api::Dynamic::Schema::Klass::Attribute::BaseController

  private

  def base_scope
    @base_scope ||= schema_attr.normalizations
  end

  class Select2
    include ::Select2::ActiveRecord

    def results
      @results ||= klass.where(params[:where]&.permit! || {}).limit(100).all # TODO improve
    end
  end
end
