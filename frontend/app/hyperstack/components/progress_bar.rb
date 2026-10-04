class ProgressBar < HyperComponent

  collect_other_params_as :others

  render do
    DIV(class: "progress position-relative #{progress_css_class}") do
      if indeterminate?
        DIV(class: "progress-bar indeterminate") do
        end
        DIV(class: "justify-content-center d-flex position-absolute w-100") do
          if info.present?
            info
          else
            current
          end
        end
      else
        DIV(class: "progress-bar bg-#{color} #{progress_bar_css_class}", style: {width: percentage_s}) do
        end
        DIV(class: "justify-content-center d-flex position-absolute w-100 #{percentage_color}") do
          if info.present?
            "#{percentage_s} ( #{info} )"
          else
            percentage_s
          end
        end
      end
    end
  end

  def percentage
    return 100 if complete?
    return 0 if total == 0
    return ((current / total) * 100).to_i
  end

  def percentage_s
    "#{percentage}%"
  end

  def percentage_color
    percentage > 50 ? 'text-white' : 'text-dark'
  end

  def event
    others[:event]
  end

  def indeterminate?
    others[:indeterminate] || event.lengthComputable
  end

  def current
    others[:current] || event.loaded
  end

  def total
    others[:total] || event.total
  end

  def complete?
    (total != 0 && current >= total) || others[:complete] || event.type == 'loadend'
  end

  def progress_css_class
    others[:className]
  end

  def progress_bar_css_class
    others.dig(:bar, :class)
  end

  def color
    others[:color] || 'primary'
  end

  def info
    others[:info]
  end

end
