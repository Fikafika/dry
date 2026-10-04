# frozen_string_literal: true

class Api::Dynamic::Schema::Reserved::BaseController < Api::Dynamic::BaseController
  include LoadSchema

  around_action :enable_notification
  around_action :sidekiq_throttle_user

  prepend_around_action :load_schema

  private

  def demodulized_klass_name
    raise NotImplementedError
  end

  def schema_name
    @schema_name ||= params[:schema_id].classify_permalink
  end

  def schema_klass
    @schema_klass ||= find_by_id_or_name(@schema.klasses, params[:klass_id], :classify)
  end

  def where_exceptions
    super + ['schema_id', 'klass_id'] # TODO ?
  end

  def controller_class_name_to_klass_name
    "D::#{schema_name}::R::#{demodulized_klass_name}"
  end

  concerning :Cache do

    def manifest_scope
      manifest_scope_for_schema_name(schema_name)
    end

  end

end
