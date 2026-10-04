class Layout < HyperComponent
  include Hyperstack::Router::Helpers

  param :dynamic_layout, default: nil

  collect_other_params_as :other_params

  render { content }

  def content
    observe dynamic_layout if dynamic_layout
    if dynamic_layout&.deleted?
      DIV(class: 'alert alert-warning') do
        I18n.t('layout.deleted')
      end
    else
      @elements = nil # TODO
      wrap_content do
        elements
      end
    end
  end

  def wrap_content
    if elements.length > 1
      DIV(class: other_params[:class]) do
        yield.map(&:render) # doesn't work properly. Why render needed ?
      end
    else
      yield&.first
    end
  end

  def render_delegate(delegate, params = {})
    convert_dynamic_layout_element(delegate, delegate_params: params).render
  end

  private

  def elements
    return [] unless dynamic_layout&.loaded?

    #return @elements if @elements
    @elements ||= dynamic_layout.root_elements.sort_by{|e| [(e.position || 1), e.id]}.map do |element|
      convert_dynamic_layout_element(element)
    end&.compact || []

    @elements
  end

  def convert_dynamic_layout_element(element, options = {})
    result = create_element(element, options) do
      if element.component != 'InfiniteScroller'
        element.children&.sort_by{|e| [(e.position || 1), e.id]}.map do |c|
          convert_dynamic_layout_element(c, options)
        end.compact
      end
    end
    return result
  end

  def create_element(element, options, &block)
    klass = element.component.safe_constantize
    return nil unless klass

    if klass.class.name == 'Hyperstack::Component::Element'
      result = ::Hyperstack::Component::ReactAPI.create_element(element.component.underscore, component_params(element, options)) do
        yield(element, block)
      end
    else
      result = klass.create_element(component_params(element, options)) do
        yield(element, block)
      end
    end
    return result
  end

  def component_params(element, options) #component_params: gathers all the children attributes in a hash
    if element.component_params_converter
      converter = element.component_params_converter.get_instance #take ParamConverter class associated to the good element
      options = options.merge(element.component_params_converter_options) if element.component_params_converter_options
      options.merge!(layout_params: other_params)
      converted_params = converter.apply(request.params, options)
      result = converted_params

      if element.component == 'InfiniteScroller'
        # InfiniteScroller works differently
        result[:layout] = self
        result[:component_params] = element.component_params
        result[:delegate] = element.children.first
      elsif element.component == 'Form'
        # allow overide params of form. is this ok for all components ?
        result = element.component_params.merge(converted_params)
      else
        result.merge!(element.component_params)
      end

    else
      result = element.component_params.dup # dup needed ?
    end

    return result
  end

  def request
    other_params[:request] || super
  end

  class ParamsConverter

    @@converters_for = {}

    def self.converter_for(*component_classes)
      component_classes.each do |c|
        @@converters_for[c] ||= Set.new
        @@converters_for[c] << self.name
      end
    end

    def self.converters_for
      @@converters_for
    end

    def self.get_instance
      @instance ||= self.new
    end

    def apply(params, options = {})
      return {}
    end

    def dynamic_klass(schema_name, route_key)
      result = "D::#{schema_name&.classify_permalink}".safe_constantize&.const_get_by_route_key(route_key)
      $stderr.puts "fail to find route key #{route_key.inspect} for #{schema_name.inspect}" unless result
      return result
    end

  end

  class ParamsMapping < ParamsConverter

    def apply(params, options = {})
      result = {}
      options&.each do |result_key, key|
        if params&.has_key?(key)
          result[result_key] ||= params[key]
        end
      end
      return result
    end

  end

end
