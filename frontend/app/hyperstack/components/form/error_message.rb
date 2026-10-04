class Form::ErrorMessage < HyperComponent

  param :timestamp, default: nil
  collect_other_params_as :other_params

  render{ content }

  def form
    other_params[:form] || ::Form.current
  end

  def content
    if form
      if form.dynamic_form
        message = form.submission.errors['message']
      elsif form.record
        message = form.record.errors['message']
      end
    end
    return unless message.is_a?(String)
    DIV class: 'alert alert-danger', role: 'alert' do
      message == 'error' ? I18n.t("shared.error") : message
    end
  end

end
