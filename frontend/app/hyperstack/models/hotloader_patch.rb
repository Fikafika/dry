# backtick_javascript: true

$eval_proc = proc do |file_name, s|
  $_hyperstack_reloader_file_name = file_name
  begin
    compiling_options = __OPAL_COMPILER_CONFIG__.merge({
      eval: true,
      file: file_name,
      enable_source_location: true,
    })

    if file_name.start_with?('models/')
      s = "#{s};App.reload"
    end

    code = Opal.compile s, compiling_options

    %x{
      return (function(self) {
        return eval(#{code});
      })(self)
    }
  rescue Exception => e
    e.set_backtrace(e.backtrace.first) # other lines of the backtrace are useless
    top = ::Hyperstack::Internal::Component::TopLevelRailsComponent.mounted_components.first
    if top
      top.instance_variable_set(:@err, [e.message, {componentStack: e.backtrace.join("\n")}])
      Hyperstack::Component.force_update!
    end
    raise e
  end
end

module HotloaderPatch
end
