module Dynamic
  class Cascade < ::Dynamic::Base

    def self.api_path
      @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'cascades'].join('/')
    end

  end
end
