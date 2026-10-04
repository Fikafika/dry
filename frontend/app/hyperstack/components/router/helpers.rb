module Router
  module Helpers

    # TODO submit a merge request to hyperstack
    def Link(to, opts = {}, &children)
      if opts[:search] || opts[:hash]
        opts[:to] = {}.tap do |hash|
          hash[:pathname] = to
          hash[:search] = opts.delete(:search) if opts[:search]
          hash[:hash] = opts.delete(:hash) if opts[:hash]
        end.to_n
      else
        opts[:to] = to
      end
      React::Router::DOM::Link(opts, &children)
    end

  end
end
::Hyperstack::Router::Helpers.include(::Router::Helpers) unless (::Hyperstack::Router::Helpers < ::Router::Helpers) # TODO submit a merge in hyperstack
