module WindowTitle
  extend ActiveSupport::Concern

  included do
    after_render do
      change_window_title
    end
  end

  def change_window_title
    t = window_title
    if @previous_window_title != t
      $window.document.title = t
      @previous_window_title = t
    end
  end

  def window_title
    [page_title, ::App.current_community&.name, I18n.t('shared.application_name')].compact.join(' - ') # asume page_title is defined
  end

end
