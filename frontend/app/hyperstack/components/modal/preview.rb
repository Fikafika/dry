
class Modal::Preview < ::Modal
  param :title, default: nil
  param :text, default: nil
  param :cancel_text, default: nil

  render { content }

  def show
    true
  end

  def title
    title
  end

  def body
    text
  end

  def cancel_btn_text
    cancel_text
  end

  def footer
    BUTTON(class:"btn bg-light mr-2", type:"button") do
      cancel_btn_text
    end.on(:click) do |event|
      cancel
    end
  end

  def default_size
    'lg'
  end
end