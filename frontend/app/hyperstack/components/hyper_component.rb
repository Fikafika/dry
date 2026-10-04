# backtick_javascript: true

require 'components/router/resources'
require 'components/router/helpers'

class HyperComponent
  include Hyperstack::Component
  include Hyperstack::State::Observable
  include ::Router::Resources::Request::Helpers

  param_accessor_style :accessors

  def observe(*args, &block)
    result = block && block.call || args.last
    if args.last&.respond_to?(:mutate)
      Hyperstack::Internal::State::Mapper.observed! args.last
    end
    Hyperstack::Internal::State::Mapper.observed! self
    result
  end

  def focus_later(css_selector, attempt = 0)
    after(0.1) do
      e = ::Element.find(css_selector)
      if e.length > 0
        e.focus
      elsif attempt < 20
        focus_later(css_selector, attempt + 1)
      end
    end
  end

  def native_state
    Hash.fast_build_from_native(`#{@__hyperstack_component_native}.state`)
  end

  module TrackChanges

    def self.included(base)
      return if base.singleton_class.included_modules.include?(ClassMethods)
      base.class_attribute :__track_changes
      base.extend ClassMethods
    end

    module ClassMethods

      def track_changes(*params)
        params.each do |param|
          method_name = "#{Array(param).join('_')}_changed?"
          next if singleton_class.methods.include?(method_name)

          path = Array(param)

          self.__track_changes ||= {}
          self.__track_changes[method_name] = path

          install_track_changes

          define_method(method_name) do
            next @__current_changes[method_name] != @__previous_changes[method_name]
          end
        end

      end

      private

      def install_track_changes
        return if @__track_changes_installed

        before_mount do
          @__previous_changes = {}
          @__current_changes = {}
        end

        self._after_new_params_callbacks.unshift( # prepend in after_new_params
          Proc.new do
            self.class.__track_changes.each do |method_name, path|
              o = self
              ok = false
              path.each do |e|
                case o
                when ::Hash
                  o = o[e]
                  ok = true
                else
                  o = o.try(e)
                  ok = true
                end
              end
              v = ok ? o : nil
              @__current_changes[method_name] = v.deep_dup
            end
          end
        )

        self._before_update_callbacks.unshift( # prepend in before_update
          Proc.new do
            @__current_changes.each do |k, v|
              @__previous_changes[k] = v
            end
            @__current_changes.clear
          end
        )

        @__track_changes_installed = true
      end
    end
  end; include TrackChanges

  module WithThrottling

    def with_throttling(duration = 0.2)
      if duration && @last_throttling && (DateTime.now < @last_throttling + duration.seconds)
        # do after a delay
        @with_throttling_delay&.abort
        duration_rest = (@last_throttling + duration.seconds - DateTime.now)
        @with_throttling_delay = after!(duration_rest) do
          @last_throttling = nil
          @with_throttling_delay = nil
          yield
        end
        @with_throttling_delay.start
      else
        # instantly
        @last_throttling = DateTime.now
        yield
      end
    end

  end

  module WithMeasure

    def self.included(base)
      return if base.singleton_class.included_modules.include?(Inherited)
      base.singleton_class.attr_accessor :__with_measure__
      base.extend ClassMethods
      base.singleton_class.prepend(Inherited)
    end

    module ClassMethods

      def with_measure(dimensions)
        self.__with_measure__ = dimensions
        imports `withMeasure(#{dimensions.to_n})(#{self.to_n})`
      end

    end

    module Inherited

      def inherited(base)
        super
        if self.__with_measure__
          base.with_measure(self.__with_measure__)
        end
      end

    end

  end

  module AfterNewParamsCallback

    def self.included(base)
      return if base.singleton_class.included_modules.include?(ClassMethods)
      base.singleton_class.prepend(ClassMethods)
      base.define_callback :after_new_params
    end

    module ClassMethods

      def render(container = nil, params = {}, &block) # TODO could be implemented with _run_before_render_callbacks ?
        super do
          run_callback(:after_new_params)
          instance_exec(&block)
        end
      end

    end
  end
  include AfterNewParamsCallback

  module HTMLEscape

    def html_escape_once(s)
      s.to_s.gsub(HTML_ESCAPE_ONCE_REGEXP, HTML_ESCAPE)
    end

  private

    HTML_ESCAPE_ONCE_REGEXP = /["><']|&(?!([a-zA-Z]+|(#\d+)|(#[xX][\dA-Fa-f]+));)/
    HTML_ESCAPE = { "&" => "&amp;", ">" => "&gt;", "<" => "&lt;", "\"" => "&quot;", "'" => "&#39;" }

  end
  include HTMLEscape

  module OutsideOfRendering

    def self.included(base)
      base.before_update do
        @rendering = true
      end
      base.after_render do
        @rendering = false
        while b = @after_render_blocks&.shift do
          b.call
        end
      end
    end

    def outside_of_rendering
      return unless block_given?
      if @rendering
        @after_render_blocks ||= []
        @after_render_blocks << lambda do
          yield
        end
      else
        after(0.01) do # why it is needed ? why after_render is during a state
          yield
        end
      end
    end

  end

end
