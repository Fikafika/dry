class DeduplicationKeys < HyperComponent
  param :klass
  param :keys, default: []
  param :attrs, default: Set.new
  param :mapped_attrs, default: nil
  param :editable, default: true
  param :clean_unknown_attrs, default: false

  collect_other_params_as :other_params

  fires :change

  after_new_params do
    @element ||= element_from_keys
    if clean_unknown_attrs
      (@element.keys - attrs.to_a).each do |attr|
        @element.delete(attr)
      end
    end
  end

  render do
    DIV(class: 'd-flex flex-row') do
      if @element.values.detect{|a| !a.empty?}
        DIV(class: 'd-flex flex-column w-100') do
          has_badge = !!@element.detect{|attr, _| !attrs.include?(attr) || (mapped_attrs && !mapped_attrs.include?(attr)) }
          @element.each do |attr, keys|
            if !keys.empty?
              DIV(class: 'align-items-center p-1 w-100 d-flex flex-wrap') do
                DIV(class: 'd-flex', style: {"minWidth": "15rem"}) do
                  klass.human_attribute_name(attr)
                end

                DIV(class: 'd-flex') do
                  if !attrs.include?(attr)
                    error_badge { I18n.t("deduplication_keys.unknown") }
                  elsif mapped_attrs && !mapped_attrs.include?(attr)
                    error_badge { I18n.t("deduplication_keys.not_used") }
                  elsif has_badge
                    badge_placeholder # for keep alignment
                  end

                  DIV(class: 'form-check form-check-inline mx-2', style: {justifyContent: 'end', width:'100%'}) do
                    keys.each_with_index do |key, k|
                      INPUT(class: 'form-check-input', type: 'checkbox', checked: key) do
                      end.on(:change) do |evt|
                        next unless editable
                        mutate keys[k] = !key
                        change!(array_keys)
                      end
                    end
                  end
                end
              end
            end
          end
        end
        if editable
          DIV do
            A(class: 'd-flex btn btn-light mr-2 h-100 align-items-center', type: 'button') do
              I(class: 'fa fa-plus')
            end.on(:click) do
              @element.each do |attr, keys|
                if !keys.empty?
                  keys.push(false)
                end
              end
              mutate
            end
          end
        end
      end
    end
    if editable
      disabled = @element.keys.sort == attrs.compact.sort ? "disabled" : ""
      DIV(class: 'dropdown multilevel-dropdown mb-3') do
        A(href: "#", class: "btn btn-light dropdown-toggle #{disabled}", 'data-toggle': 'dropdown', 'data-display': 'static') do
          I18n.t('shared.add')
        end
        DIV(class: 'dropdown-menu', style: { "overflowX": "hidden", "maxHeight": "250px" }) do
          attrs.each do |attr|
            next if @element[attr]
            A(href: "#", class: "dropdown-item") do
              klass.human_attribute_name(attr)
            end.on(:click) do
              a = @element.values.detect{|a| !a.empty?}
              keys_number = a ? a.count : 3
              @element[attr] = Array.new(keys_number, false)
              mutate
            end
          end; ""
        end
      end
    end
  end

  def element_from_keys
    result = {}
    min_size = [keys.size, 2].max
    keys&.each_with_index do |level, index|
      level&.each do |attr|
        result[attr] ||= Array.new(min_size, false)
        result[attr][index] = true
      end
    end
    return result
  end

  def array_keys
    keys = []
    @element.each do |attr, h|
      h.each_with_index do |k, i|
        if k
          (keys[i] ||= []) << attr
        end
      end
    end
    return keys
  end

  def error_badge
    SPAN(class: 'alert alert-danger m-0', style: badge_style) { yield }
  end

  def badge_placeholder
    SPAN(class: 'alert alert-danger m-0', style: badge_style.merge(opacity: 0)) { '' }
  end

  def badge_style
    {minWidth: '7.5em', fontSize: '0.6em', padding: '0.4em 1em'}
  end
end
