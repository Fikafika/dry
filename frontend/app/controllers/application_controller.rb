class ApplicationController < ActionController::Base

  def root_path
    ENV.fetch('APP_PATH_PREFIX'){'/'}
  end

  #before_action :authenticate_user!

  def acting_user
    current_user
  end

end
