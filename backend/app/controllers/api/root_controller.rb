# frozen_string_literal: true

class Api::RootController < Api::BaseController

  def ping # see Connection.prototype.cleanReopen() in frontend/app/javascript/channels/connection.js
    session.update({}) # create a session without anything in it
    set_csrf_token
    head :ok
  end

  def klass
    nil
  end

  concerning :Authentication do

    def authenticate_before_find_element?
      false
    end

  end

  concerning :Authorization do

    def skip_permissions?
      true
    end

  end

end
