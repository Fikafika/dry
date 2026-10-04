class Settings
  class Formula < HyperComponent
    param :schema
    param :form, default: nil
    param :record, default: nil
    param :prefix_path, default: nil
    param :attribute_name
    param :klass_id_attr, default: 'klass_id'
    param :help, default: nil
    param :help_position, default: nil
    param :conditions, default: []
    param :timestamp, default: nil
    param :height, default: nil

    render do
      observe schema
      Form::Element::Attribute::String(
        form: form,
        attribute_name: attribute_name,
        editor: 'formula_editor',
        lsp_url: lsp_url,
        record: record,
        prefix_path: prefix_path,
        help: help,
        help_position: help_position,
        conditions: conditions,
        timestamp: timestamp,
        height: height,
      )
    end

    def lsp_url
      return unless schema&.loaded? && form

      prefix_path = [record.class.name.demodulize.underscore]
      klass_id = form.submission.read(prefix_path + [klass_id_attr])
      klass_id ||= record.send(klass_id_attr)
      return unless klass_id

      schema_klass = schema.klasses_by_id[klass_id]
      schema_klass ||= schema.klasses.detect do |k|
        k.name.underscore == klass_id
      end
      return unless schema_klass

      href = App.location.href
      domain = href.split('/')[2]
      ws_protocol = href.start_with?('https') ? 'wss' : 'ws'
      schema_name = schema.name || schema.id
      return "#{ws_protocol}://#{domain}#{ENV['APP_PATH_PREFIX']}/api/lsp/d/#{schema_name.underscore}/#{schema_klass&.name&.underscore}"
    end
  end
end
