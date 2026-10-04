if RUBY_ENGINE == 'opal'

   # should be in activesupport/core_exct/hash/except

   class Hash
     def except(*args)
       self.inject({}){|h, a| h[a[0]] = a[1] unless args.include?(a[0]); h }
     end
   end

  # should be in activesupport/core_ext/object/deep_dup

  class Object
    def deep_dup
      self
    end
  end

  class Array
    def deep_dup
      map(&:deep_dup)
    end
  end

  class Hash
    def deep_dup
      Hash[to_a.map{|k, v| [k.deep_dup, v.deep_dup]}]
    end

  end

else

  # TODO needed by zeitwerk
  module OpalFix
  end

end
