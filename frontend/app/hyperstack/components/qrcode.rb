# backtick_javascript: true

class QRCode < HyperComponent
  param :str
  collect_other_params_as :other_params

  render do
    if img_src
      IMG(src: img_src, class: "qr-code #{other_params[:className]}")
    end
  end

  before_new_params do
    @img_src = nil if str != @previous_str
    @previous_str = str
  end

  def img_src
    return @img_src if @img_src
    `QRCode.toDataURL(#{str&.to_n}, { margin: 0 }, (err, url) => { #{@img_src} = url; })`
    return @img_src
  end
end
