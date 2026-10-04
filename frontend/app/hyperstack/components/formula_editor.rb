# backtick_javascript: true

class FormulaEditor < HyperComponent

  DEFAULT_HEIGHT = '100px'

  param :lsp_url
  param :value
  param :height, default: nil
  param :name, default: nil

  fires :change

  render do
    resizer do
      IFRAME(
        name: name,
        src: ENV['FORMULA_EDITOR_PATH'],
        class: "form-control px-0",
        style: {height: '100%'},
        scrolling: 'no',
        onLoad: Proc.new{ init },
      ) do
      end
    end
  end

  def resizer
    DIV(style: {resize: 'vertical', overflow: 'hidden', height: initial_height}) do
      yield
    end
  end

  def style
    {
      height: '100%',
    }
  end

  before_new_params do |next_params|
    if monaco_loaded? && next_params[:value].to_s != @current_value.to_s
      post_message(
        event: 'change',
        value: next_params[:value].to_s,
      )
    end
  end

  after_render do
    reload_iframe if @lsp_url != lsp_url
  end

  before_unmount do
    remove_get_message_listener
  end

  def monaco_loaded?
    @loaded
  end

  def init
    @current_value = value || ''
    @lsp_url = lsp_url
    post_message(
      event: 'start',
      formula: @current_value,
      lsp: lsp_url,
    )
    get_message do |e|
      case e.data.event
      when 'change'
        @current_value = e.data.value
        change!(@current_value)
      when 'started'
        fix_style
        @loaded = true
      end
    end
  end

  def iframe
    `#{self.dom_node}.firstChild`
  end

  def reload_iframe
    `#{iframe}.contentWindow.location.reload()`
  end

  def post_message(e)
    `#{iframe}.contentWindow.postMessage(#{e.to_n})`
  end

  def get_message(&block)
    `window.addEventListener('message', #{get_message_proc(&block)})`
  end

  def get_message_proc(&block)
    @get_message_proc ||= Proc.new do |e|
      next unless `e.source` && `e.source.name` == name
      yield(Native(e))
    end
  end

  def remove_get_message_listener
    return unless @get_message_proc
    `window.removeEventListener('message', #{@get_message_proc})`
  end

  def initial_height
    height || DEFAULT_HEIGHT
  end

  after_mount do
    observe_size
  end

  def observe_size
    `
      var ro = new ResizeObserver(entries => {
        if (#{self.mounted?}) {
          for (let entry of entries) {
            const cr = entry.contentRect;
            const container = #{iframe}.contentWindow.document.getElementById("container");
            if (container) {
              container.style.height=cr.height + 'px';
            }
          }
        }
      });
      ro.observe(#{self.dom_node});
    `
  end

  def fix_style
    `#{iframe}.contentWindow.document.body.style['overflow'] = 'hidden'`
  end

end
