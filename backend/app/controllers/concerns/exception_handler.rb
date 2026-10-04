module ExceptionHandler; extend ActiveSupport::Concern

  included do
    class Forbidden < StandardError; end

    rescue_from ActiveRecord::RecordNotFound do |e|
      render json: { message: e.message }, status: :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      Rails.logger.warn(e.record.errors.inspect)
      render json: e.record.errors.details, status: :unprocessable_content
    end

    rescue_from ActiveRecord::RecordNotUnique do |e|
      log_exception(e)
      render json: { message: e.message }, status: :unprocessable_content
    end

    rescue_from NameError do |e|
      log_exception(e)
      log_schema_stats
      render json: { message: e.message }, status: :unprocessable_content
    end

    rescue_from ActionController::ParameterMissing do |e|
      render json: { message: e.message }, status: :unprocessable_content
    end

    rescue_from ActionController::NotImplemented do |e|
      render json: { message: e.message }, status: :not_implemented
    end

    rescue_from Forbidden do |e|
      head :forbidden
    end

    rescue_from OpenSearch::Transport::Transport::Errors::Forbidden do |e|
      log_exception(e)
      render json: { data: [], recordsTotal: 0 }, status: :ok
    end

    rescue_from ::UneekPermission::UnauthorizedAction do |e|
      render json: { message: e.message }, status: :unauthorized
    end

    rescue_from ActionController::InvalidAuthenticityToken do |e|
      render json: { error: 'invalid_authenticity_token', message: e.message }, status: :unprocessable_content
    end

    rescue_from ActiveRecord::StatementInvalid do |e|
      case e.message
      when /PG::UndefinedColumn/
        e.message =~ /column \"(.+)\" does not exist/
        column = $1
        render json: { error: 'undefined_column', column: column }, status: :unprocessable_content
      else
        Rails.logger.warn(e.message)
        render json: { error: 'statement_invalid' }, status: :unprocessable_content
      end
    end

  end

private

  def log_exception(e)
    return unless Rails.logger.error?
    Rails.logger.error(e.inspect)
    e.backtrace.each do |b|
      Rails.logger.error(b)
    end
  end

  def log_schema_stats
    Rails.logger.error("Schemas:")
    (Dynamic::Schema.loaded_schemas.values + Dynamic::Schema.where.not(name: Dynamic::Schema.loaded_schemas.keys).all.to_a).each do |schema|
      Rails.logger.error("  #{schema.name}")
      Rails.logger.error("    updated_at: #{schema.updated_at}")
      Rails.logger.error("    loaded: #{schema.loaded?}")
      Rails.logger.error("    stale: #{schema.stale?}")
      Rails.logger.error("    locked_for_read: #{Thread.current[:"dynamic_schema_locked_for_read_#{schema.id}"].inspect}")
      Rails.logger.error("    locked_for_write: #{Thread.current[:"dynamic_schema_locked_for_write_#{schema.id}"].inspect}")
    end
  end
end
