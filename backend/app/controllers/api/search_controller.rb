class Api::SearchController < ApplicationController
  include ExceptionHandler

  def index
    @elements = elements
    render json: @elements.to_json, status: :ok
  end

  private

  def elements
    if params[:select2]
      self.class::Select2.new(klasses, params)
    end
  end

  def klass
    return @klass if @klass
    @klass = params[:klass_name].safe_constantize
    @klass = "#{@klass}::Base".constantize unless @klass.is_a?(Class)
    return @klass
  end

  def klasses
    return @klasses if @klasses
    @klasses = []
    if params[:klass_names]
      params[:klass_names].each do |klass_name|
        klass_ = klass_name.safe_constantize
        klass_ = "#{klass_}::Base".safe_constantize unless klass_.is_a?(Class)
        @klasses << klass_ if klass_.is_a?(Class)
      end
    end
    if params[:klass_name]
      @klasses = [klass]
    end
    return @klasses
  end

  class Select2

    include ::Select2::Elasticsearch
  end

end