class Crm
  class RulePanel < Sheet

    render { content }

    def content
      return unless action == 'rules'
      DIV(class: "d-flex flex-row#{'-reverse' if side == "left"} align-items-center") do
        Crm::Sheet::CloseButton(side: side)
        if member && User.current.admin?(schema_name)
          SPAN(class: 'flex-grow-1 text-center pt-1') do
            edit_page_title
          end
          BUTTON(class: 'ib btn btn-transparent-light-yiq border-0 rounded-0 text-break') do
            I(class: 'fas fa-plus')
          end.on(:click) do
            mutate rules.unshift(new_record) if rules.none?{|record| record.id.nil?}
          end
        else
          SPAN(style: {margin: 'auto'}) do
            UneekPermission::Rule.model_name.human
          end
        end
      end
      if User.current.admin?(schema_name)
        if !member
          ::Settings::Schema::Klasses::Permissions::Preview(
            schema_klass: schema_klass,
            attributes: attributes,
            associations: associations,
            attachments: attachments,
            rules: rules,
            reload: @reload,
            css_class: 'border-top',
          ).on(:element_selected) do |name, type|
            opposite_panel_param = (panel_param == 'rp' ? 'lp' : 'rp')
            case type
            when 'klass'
              App.history.push(App.location.add_params(opposite_panel_param => "#{current_location}%3Fmember%3D#{klass_name}%26type%3Dklass"))
            when 'attr', 'assoc', 'attach'
              App.history.push(App.location.add_params(opposite_panel_param => "#{current_location}%3Fmember%3D#{name}%26type%3Dattr"))
            end
          end
        else
          ::Permission::Manager(
            rules: rules.reverse.select{|record| member == klass_name ? record.attr.nil? : record.attr == member},
            params_for_new_record: new_record_params,
            possible_attributes_values: possible_attributes_values || [],
            enum_values_proc: Proc.new do |attr|
              enum_values_from_attr(attr)
            end,
            on_instance: true,
            klass_name: request.params[:klass_id],
            schema_name: request.params[:schema_id],
          )
        end
      else
        DIV(class: 'alert alert-warning') do
          I18n.t('activerecord.exceptions.unauthorized')
        end
      end
    end

    def edit_page_title
      if is_attribute
        associations.detect {|asso| asso.attr_name == member}&.human_name || attributes.detect {|attr| attr.name == member}&.human_name
      else
        klass.model_name.human
      end
    end

    def new_record_params
      {
        klass_name: klass.name,
        attr: is_attribute ? member : nil,
        instance_id: instance_id,
      }
    end

    def possible_attributes_values
      if schema.const.feature_enabled?('Dynamic::Permission::Feature')
        observe options_for_indexed_json = schema_klass.options_for_indexed_json
        const_klass = klass_name.safe_constantize
        return nil unless const_klass
        return options_for_indexed_json_to_options(const_klass, options_for_indexed_json)
      else
        # TODO get all attributes from all associations (limited to 2 level of nested association)
        # This should be the default behavior since users can also be external API's
      end
    end

    def options_for_indexed_json_to_options(klass, options, prefix = '')
      return unless options
      results = []

      if options[:only]
        options[:only].each do |attr|
          unsupported_attribute = ::UneekPermission::Rule::DOMAIN_OPERATION_METHODS_BY_TYPE[klass.attributes.dig(attr, 'type')].nil?
          next if unsupported_attribute || attr == 'deleted_at'
          results << {
            label: klass.human_attribute_name(attr),
            value: "#{prefix}#{attr}",
          }
        end
      end

      if options[:include]
        options[:include].each do |asso, asso_options|
          next unless klass.reflect_on_association(asso) && klass.reflect_on_association(asso)&.options[:class_name]
          k = klass.reflect_on_association(asso)&.options[:class_name].safe_constantize
          results << {
            label: klass.human_attribute_name(asso),
            value: "#{prefix}#{asso}",
            options: options_for_indexed_json_to_options(k, asso_options, "#{prefix}#{asso}."),
          }
        end
      end

      return results.sort_by{|r| r[:label]}
    end

    def enum_values_from_attr(attr)
      return [] unless attr
      attrs = attr.split('.')
      c_klass = schema_klass

      if attrs.length > 1
        attrs[0...-1].each do |a|
          trgt = c_klass.associations.detect { |assoc| assoc.name == a }
          break unless trgt&.target_klass_id
          c_klass = schema.klasses.detect { |k| k.id == trgt.target_klass_id }
        end
      end
      attribute = c_klass.attrs.detect{ |a| a.name == attrs[-1] }
      return [] unless attribute&.type == 'Enum'

      observe enum_values = Dynamic::Schema::Attribute::Enum::Value.where(
        attr_id: attribute.name,
        schema_id: request.params[:schema_id],
        klass_id: c_klass.id
      ).all
      enum_values.map { |val| { name: val.name, human_name: val.human_name } }
    end

    def rules
      observe @rules = ::UneekPermission::Rule.where(
        klass_name: klass_name,
        instance_id: instance_id,
        schema_id: schema.id
      ).all
    end

    def schema_klass
      observe @schema_klass = Dynamic::Schema::Klass.where(schema_id: schema_name).find(klass_name.demodulize)
    end

    def schema
      observe @schema = Dynamic::Schema.load(schema_name)
    end

    def associations
      @asssociations = schema_klass.associations.per(1000).all {reload}
    end

    def attributes
      @attrs = schema_klass.attrs.per(1000).all {reload}
    end

    def attachments
      @attachments = schema_klass.attachments.per(1000).all {reload}
    end

    def reload
      @reload = Time.now.to_f
      mutate
    end

    def klass
      klass_name.safe_constantize
    end

    def record
      klass.find(instance_id)
    end

    def instance_id
      request.params[:id]
    end

    def current_location
      url_for(record: record, action: 'rules')
    end

    def member
      request.params[:member]
    end

    def is_attribute
      request.params[:type] == 'attr'
    end

  end
end
