class Api::MimeTypesController < ApplicationController

  def index
    render json: Marcel::EXTENSIONS.map{|k, v| {extension: k, mime_type: v} }, status: :ok
  end

end
