# frozen_string_literal: true

class Api::Dynamic::Schema::Reserved::DocGen::TemplatesController < Api::Dynamic::Schema::Reserved::BaseController

  class Select2 < Api::Dynamic::Schema::Reserved::BaseController::Select2 # TODO where

    def results
      @results ||= klass.with_translations(I18n.locale).where(["unaccent(LOWER(#{klass.translated_column_name('name')})) LIKE unaccent(LOWER(?))", "%#{term}%"]).where(params['where']&.permit!&.to_h || {}).limit(100).all
    end

  end

  private

  def demodulized_klass_name
    'DocGen::Template'
  end

  def base_scope
    klass.where(class_name: schema_klass.const_absolute_name)
  end

end
