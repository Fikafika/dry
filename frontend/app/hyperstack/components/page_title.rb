# backtick_javascript: true

require 'active_support/concern'

module PageTitle
  extend ActiveSupport::Concern

  included do
    after_new_params do
      set_page_title
    end

    def set_page_title
      if @page_title.nil? || @page_title != @previous_page_title
        @page_title = page_title
        @previous_page_title = @page_title
      end
    end

    def page_title
    end
  end

end
