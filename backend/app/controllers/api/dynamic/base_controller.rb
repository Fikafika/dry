class Api::Dynamic::BaseController < Api::BaseController

  private

  def elements
    if params[:select2]
      self.class::Select2.new(base_scopes, params)
    else
      return super
    end
  end

  def to_json(a)
    result = a.respond_to?(:as_deep_json) ? a.as_deep_json(deep_json_options) : a
    if params[:pretty_print]
      result = JSON.pretty_generate(result)
    else
      result = result.to_json
    end
    return result
  end

  def deep_json_options
    r = params.to_unsafe_hash.slice('only', 'include')
    predefined_include = params.dig(:predefined_include, :name)
    if predefined_include && klass&.respond_to?(predefined_include)
      args = params.dig(:predefined_include, :args)&.permit!&.to_h&.with_num_keys_to_array || []
      r['include'] = klass.send(predefined_include, *args) # TODO rewrite. There is a security problem here. There should be a list of methods for predefined includes
    end
    predefined_only = params.dig(:predefined_only, :name)
    if predefined_only && klass&.respond_to?(predefined_only)
      args = params.dig(:predefined_only, :args)&.permit!&.to_h&.with_num_keys_to_array || []
      r['only'] = klass.send(predefined_only, *args)
    end
    r.merge!({ :secure => false })  # TODO don't keep that !!
    r
  end

  def special_param_keys
    super + ['pretty_print', 'predefined_include', 'predefined_only']
  end

  class Select2
    include ::Select2::ActiveRecord
  end

end
