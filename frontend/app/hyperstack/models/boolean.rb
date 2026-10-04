if RUBY_ENGINE != 'opal'

  unless defined?(Boolean)
    module Boolean
    end

    class TrueClass
      include Boolean
    end
    class FalseClass
      include Boolean
    end
  end

  class Object
    def Boolean(str)
      return str.to_s == 'true'
    end
  end

end
