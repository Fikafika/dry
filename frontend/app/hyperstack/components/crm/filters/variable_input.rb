class Crm
  module Filters
    class VariableInput < HyperComponent

      param :value
      param :possible_values

      fires :change

      render do
        Form(record: HyperResource::Base.new(variable: value), class: 'flex-grow-1') do
          Form::Element::Attribute::SerializedArray(
            attribute_name: 'variable',
            possible_values: possible_values,
            accept_empty_value: true,
            editor: 'tree_select',
            show_label: false,
            class: 'mb-0',
          ).on(:change) do |attr, form|
            variable = form.submission.params.dig('hyper_resource', 'variable')
            change!({variable: variable}) if variable.present?
          end
        end
      end

    end
  end
end
