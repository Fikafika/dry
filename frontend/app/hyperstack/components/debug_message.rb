# backtick_javascript: true

require 'active_support/concern'

class DebugMessage < HyperComponent

  param :component, default: nil
  param :error, default: nil
  param :info, default: nil

  attr_accessor :position

  render { content }

  def content
    if error
      init
      console_error
      DIV(class: 'alert alert-danger overflow-auto m-2') do
        if Hyperstack.env == 'development'
          DIV(class: 'text-break pb-2') do
            file_name_and_line
          end
          DIV(class: 'text-break pb-2') do
            error_message
          end
          DIV(class: 'text-break pb-2') do
            line_with_cursor_from_source&.each do |l|
              PRE(class: 'm-0') do
                l
              end
            end
          end
        elsif Hyperstack.env == 'production'
          SPAN do
            I18n.t('shared.error')
          end
        end
      end
    else
      DIV {}
    end
  end

  def init
    if @previous_error != error
      @previous_error = error
      observe @position = error.original_source_location if error.is_a?(Exception)
    end
  end

  def file_name_and_line
    "#{position.source}:#{position.line}" if position&.source
  end

  def error_message
    return unless error
    error.try(:message) || error.inspect
  end

  def line_with_cursor_from_source
    return position.line_with_cursor_from_source if position&.line
  end

  def component_inspect
    return unless component
    component.class.name + "(" + component.props.map{|k, v| "#{k}: #{v.inspect}" }.join(', ') + ")"
  end

  def console_error
    m = console_message
    return unless m
    `console.error(#{m})`
  end

  def console_message
    return unless position&.source
    parts = []
    parts << file_name_and_line + "\n"
    parts << error.message + "\n" if error.try(:message)
    l = line_with_cursor_from_source
    parts.concat(l.map{|l| "#{l}\n"}) if l
    return parts.join
  end

end
