class Crm
  class ListItem < HyperComponent
    #param :photo_url, default: 'https://cdn4.iconfinder.com/data/icons/heros/100/Super_Hero_1-512.png', type: String
    param :content
    param :klass, default: nil

    render() do
      DIV(class: 'media') do
        # if photo_url
        #   IMG(class: 'img-fluid', src: photo_url, style: {'max-width': '100px'}) # TODO
        # else
        DIV(class: "fa fa-user fa-2x mr-3")
        DIV(class: 'media-body') do
          DIV(class: 'p') do
            content.first_name
          end
          DIV(class: 'p') do
            content.last_name
          end
        end
      end
    end

  end
end
