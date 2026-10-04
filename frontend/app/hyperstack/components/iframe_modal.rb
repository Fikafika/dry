# backtick_javascript: true

class IFrameModal < Modal

  def size
    "90"
  end

  def body
    IFRAME(
      src: `#{@event.to_n}.relatedTarget.dataset.src`,
      style: {width: '88vmax', height: '88vh'},
      onLoad: Proc.new{|e| `console.log(e.currentTarget.contentWindow.window)`}.to_n
      # `this.style.width=(this.contentWindow.document.body.scrollWidth)+'px';`
    )
  end

  def footer
    BUTTON(class:"btn bg-light mr-2", type:"button") do
      close_btn_text
    end.on(:click) do |event|
      cancel
    end
  end

  def close_btn_text
    I18n.t('shared.close')
  end
end
