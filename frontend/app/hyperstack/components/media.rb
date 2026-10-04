class Media < ::Layout::Element

  render { content }

  def content
    DIV(class: 'media') do
      super { children.render }
    end
  end

  class Photo < ::HyperComponent

    collect_other_params_as :other_params

    render { content }

    def content
      if photo_url.present?
        IMG(class: 'img-fluid', src: photo_url, style: {'max-width': '100px'})
      else
        DIV(class: "fa fa-#{icon || 'square-o'} fa-2x mr-3")
      end
    end

    def photo_url
      other_params[:photo_url]
    end

    def icon
      other_params[:icon]
    end

  end

  class Body < ::Layout::Element
    render { content }

    def content
      DIV(class: 'media-body') do
        super { children.render }
      end
    end

  end

end
