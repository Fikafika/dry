class Crm::DocGen::Modal < ::Modal
  include ::SchemaLoading

  render { content }

  def title
    I18n.t('doc_gen.generate')
  end

  def body
    record = build_record
    Form(record: record) do
      if multiple?
        Form::Element::Association::HasMany(
          attribute_name: 'record_ids',
          editor: 'hidden',
          polymorphic: false,
        )
      else
        Form::Element::Association::BelongsTo(
          attribute_name: 'record_id',
          editor: 'hidden',
        )
      end
      Form::Element::Association::BelongsTo(
        attribute_name: 'template_id',
        label: I18n.t('activerecord.attributes.dynamic/doc_gen/generation.template_id'),
        target_klass_url: schema.const::R::DocGen::Template.collection_path(schema_id: request.params[:schema_id], klass_id: klass_name),
      ).on(:change) do |value, form, element|
        if value&.default_attachment && !form.submission.read(['generation', 'attachment'])
          form.submission.write_from_user(['generation', 'attachment'], value&.default_attachment)
        end
        form.mutate
      end
      klass = multiple? ? record.records[0]&.class : record.record.class
      Form::Element::Attribute::Enum(
        attribute_name: 'attachment',
        possible_values: klass&.reflect_on_all_attachments&.map{|a| { label: klass.human_attribute_name(a.name), value: a.name }} || [],
      )
      Form::Element::Attribute::String(
        attribute_name: 'output_name',
      )
      Form::ErrorMessage()
    end
  end

  def confirm
    Form.current.submit.then do |response|
      if response[:success]
        super
      end
    end
  end

private

  def default_size
    'md'
  end

  def klass_name
    klass_route_key = record_klass_name_to_generate ? record_klass_name_to_generate.model_name.route_key : request.params[:klass]
    schema.const.const_get_by_route_key(klass_route_key).name.demodulize.underscore
  end

  def record_klass_name_to_generate
    result = nil
    if multiple?
      result = @event_params[0][:records].present? ? @event_params[0][:records].first.class : nil
    else
      result = @event_params[0][:record].present? ? @event_params[0][:record].class : nil
    end
    return result
  end

  def build_record
    record = schema.const::R::DocGen::Generation.new(klass_id: klass_name)
    if multiple?
      record.records = @event_params[0][:records] || []
    else
      record.record = @event_params[0][:record]
    end
    record
  end

  def multiple?
    @event_params[0].has_key?(:records)
  end

end
