module Dynamic

  module Api

    module Concern

      def load_constants(concern, schema)
        const = schema.klasses_by_id[concern.klass_id]&.const
        return unless const

        api_data = const.instance_variable_get(:@api_data)
        if !api_data
          api_data = {}
          const.instance_variable_set(:@api_data, api_data)
        end

        input_mapping = concern.options.detect{|o| o.name == "input_mapping"}&.value || {}
        output_mapping = concern.options.detect{|o| o.name == "output_mapping"}&.value || {}
        api_url = concern.options.detect{|o| o.name == "api_url"}&.value || ''
        fill_not_in_form_fields = concern.feature.options.detect{|o| o.name == "fill_not_in_form_fields"}&.value || false
        http_options = self.http_options(input_mapping, output_mapping, api_url)
        process_results = self.process_results

        input_mapping.each do |key, value|
          api_data[value] = {
            url: api_url,
            term_param: key,
            fill_not_in_form_fields: fill_not_in_form_fields,
            http_options: http_options,
            process_results: process_results,
            convert_selected_item: convert_selected_item(output_mapping),
          }
        end

        const.define_singleton_method :api_data do
          @api_data
        end
      end

      def http_options
        {}
      end

      def process_results
        nil
      end

      def convert_selected_item(output_mapping)
        return Proc.new do |item, &block|
          output = item['value']
          result = {}
          output_mapping.each do |output_key, attr_name|
            splitted_key = output_key.split('.')
            result[attr_name] = output.dig(*splitted_key)
          end
          item['record'] = result
          block&.call(item)
        end
      end

    end

  end

end
