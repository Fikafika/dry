class ErrorMessage < HyperComponent

  collect_other_params_as :other_params

  render { content }

  def content
    if errors?
      DIV(class: "alert alert-danger #{other_params[:className]}") do
        if error_lines.any?
          error_lines.each do |e|
            DIV(dangerously_set_inner_HTML: { __html: e })
          end
        else
          I18n.t('shared.error')
        end
      end
    else
      DIV {}
    end
  end

  def errors?
    errors.try(:any?)
  end

  # eg.
  # [{ record_type: 'D::Uneek::Contact', record_id: 1 , details: {name: [{error: 'blank'}], value: [{error: 'too_long', count: 2}] }}]
  # =>
  # [{ record: <D::Uneek::Contact id: 1>, attr: 'name', error: 'blank' }, { record: <D::Uneek::Contact id: 1>, attr: 'value', error: 'too_long', count: 2 }]

  def errors
    errors_ = other_params[:errors] || record_errors
    return [] unless errors_
    result = []
    errors_.each do |e|
      record = e[:record_type]&.safe_constantize&.new(id: e[:record_id])
      if e[:details]
        e[:details].each do |k, v|
          Array(v).each do |h|
            result << h.merge({ record: record, attr: k})
          end
        end
      else
        result << e
      end
    end
    return result
  end

  def record_errors
    return unless other_params[:record]
    result = []
    errors = other_params[:record].errors
    case errors
    when Hash
      errors.each do |k, v|
        next if k == 'message'
        next unless v.is_a?(Array)

        v.each do |value|
          h = {}
          h[:error] = value[:error]
          h[:attr] = k
          h[:record_type] = record.class.name
          h[:record_id] = record.id
          result << h
        end
      end
    when Array
      errors.each do |r|
        r[:record_type] = record.class.name
        r[:record_id] = record.id
        result << r
      end
    end

    return result
  end

  def error_lines
    begin
      errors.select{|e| show_error?(e) }.map do |e|
        if e[:type]
          l = "#{e[:type]}: #{html_escape_once(e[:message])}"
          if Hyperstack.env == 'development'
            l = %Q[#{l}. <abbr class="" title="#{e[:backtrace].join("\n")}">stacktrace</abbr>]
          end
          l
        else
          record_klass = e[:record] || e[:record_type].safe_constantize
          [
            e[:record]? [record_klass&.model_name&.human, e[:record]&.id].join('-') : nil,
            (record_klass&.human_attribute_name(e[:attr])&.downcase || e[:attr]),
            I18n.error(e, e[:record], e[:attr])
          ].compact.join(' ')
        end
      end
    rescue Exception => e
      []
    end
  end

  def show_error?(error)
    return true unless other_params[:blacklist]
    if other_params[:blacklist].is_a?(Hash)
      return !!other_params[:blacklist].dig(error[:record_type], error[:record_id], error[:attr])
    elsif other_params[:blacklist].is_a?(Regexp)
      return !(error[:attr]).match(other_params[:blacklist])
    end
  end

  def record
    other_params[:record]
  end
end
