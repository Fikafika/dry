require 'opal'

module Native
  class Object

    def slice(*args)
      r = {}
      args.each do |k|
        r[k] = self[k]
      end
      return r
    end

    def except(*args)
      r = {}
      except_keys = {}
      args.each do |k|
        except_keys[k] = true
      end
      self.each do |k,v|
        next if except_keys[k]
        r[k] = v
      end
      return r
    end

    def to_h
      ::Hash.new(self.to_n)
    end

    def tap(&block)
      yield self
      self
    end

  end

end
