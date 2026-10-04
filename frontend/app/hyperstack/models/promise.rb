# backtick_javascript: true

if RUBY_ENGINE == 'opal'

  require 'opal'

  class Promise
    def to_n
      %x{
        return new Promise((resolve, reject) => {
          #{
            self.then do |value|
              `resolve(#{value})`
            end.fail do |error|
              `reject(#{error})`
            end
          }
        });
      }
    end
  end

else

  # TODO
  class Promise
  end

end
