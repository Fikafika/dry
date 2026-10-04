# backtick_javascript: true
class ContextDatePicker < ContextMenu
  param :initial_date, default: nil
  param :input_style, default: {}
  param :css_class, default: ''

  fires :date_selected

  before_mount do
    @input_ref = `React.createRef()`
  end

  render do
    next unless position
    DIV(class: "dropdown-menu context-menu #{css_class}", style: {position: css_position}) do
      render_input_date
    end
  end

  def render_input_date
    default_style = {
      opacity: 0,
      width: '1px',
      height: '1px',
      position: 'absolute',
      pointerEvents: 'none'
    }
    style = default_style.merge(input_style)
    INPUT(
      ref: @input_ref,
      type: 'date',
      value: initial_date,
      style: style
    ).on(:change) do |evt|
      date_selected!(evt.target.value) if evt.target.value
    end.tap do
      `requestAnimationFrame(() => {
        const nativeInput = #{@input_ref}.current;
        if (nativeInput) {
          try {
            nativeInput.showPicker();
          } catch (error) {
            nativeInput.focus();
            nativeInput.click();
          }
        }
      })`
    end
  end
end