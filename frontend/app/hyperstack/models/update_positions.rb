module UpdatePositions
  def self.included(base)
    base.extend(Methods)
  end

  module Relation
    def self.included(base)
      base.include(Methods)
    end
  end

  module Methods

    def update_positions(params)
      path = "#{self.api_path}/update_positions.json"
      payload = params
      promise = Promise.new
      ::HyperResource::HTTP.send(:patch, path, payload: payload) do |response|
        if response.ok?
          data = response.json rescue {}
          invalidate_cache_for_update_positions([:all, :count], where: {params[:attr] => params[:target]})
          invalidate_cache_for_update_positions([:all, :count], where: {params[:attr] => params[:source]})
          promise.resolve(data.merge(success: true, status_code: response.status_code))
        else
          errors = response.json rescue {:message => 'error'}
          promise.resolve(success: false, errors: errors, status_code: response.status_code)
        end
      end
      return promise
    end

    private

    def invalidate_cache_for_update_positions(kinds, where)
      kinds.each do |kind|
        cache[kind].each do |cache_key, result|
          next unless where.all? {|key, value| cache_key[key] == value}
          result.stale = true
        end
      end
    end
  end
end