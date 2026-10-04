# frozen_string_literal: true

class ApplicationController < ActionController::Base

  include ::MonkeyPatch::SessionChannel::Controller

  after_action :set_csrf_token, if: :session_id_changed?

  def root_path
    ENV.fetch('APP_PATH_PREFIX'){'/'}
  end

  private

  def session_id_changed?
    request.session['old_session_id'].present?
  end

  def set_csrf_token
    headers['X-CSRF-Token'] = form_authenticity_token
    headers[::Rack::CACHE_CONTROL] = 'no-store'
  end

  concerning :Versioning do

    def info_for_paper_trail
      return {
        created_in: :controller,
      }
    end

  end

end
