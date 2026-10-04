# frozen_string_literal: true

class Api::Dynamic::Schema::Reserved::DocGen::Merge::FilesController < Api::Dynamic::Schema::Reserved::BaseController

  private

  def demodulized_klass_name
    'DocGen::Template'
  end

  def base_scope
    klass.where(class_name: schema_klass.const_absolute_name, id: params[:template_id]).first.files
  end

end
