module Dynamic
  class ReservedRelation < ::HyperResource::Relation

    @@schema_updated_at = nil

    def initialize(klass, options = {})
      options[:includes] ||= klass.try(:includes_for_load) # TODO generalize default includes
      super(klass, options)
    end

    def where(args)
      compute_reserved_klass_from_schema_name(args)
      super
    end

    def merge_where(args)
      compute_reserved_klass_from_schema_name(args)
      r = super
      r.instance_variable_set(:@schema_name, @schema_name)
      puts "schema_name is nil: #{self}" if @schema_name.nil?
      r
    end

    def compute_reserved_klass_from_schema_name(args)
      return if @klass.name.start_with?('D::')
      @schema_name = args[:schema_name]&.classify_permalink
      return unless @schema_name
      reserved_klass = "D::#{@schema_name}::R::#{@klass.name.gsub(/^Dynamic::/, '')}".safe_constantize
      @klass = reserved_klass if reserved_klass
    end

    def all(&block)
      stale! if schema_stale?
      @@schema_updated_at = schema.updated_at if schema
      super(&block)
    end

    def first_or_last(*args)
      stale! if schema_stale?
      @@schema_updated_at = schema.updated_at if schema
      super
    end

    def count(*args)
      stale! if schema_stale?
      @@schema_updated_at = schema.updated_at if schema
      super
    end

    def schema_stale?
      return false unless schema
      return @@schema_updated_at && @@schema_updated_at != schema.updated_at
    end

    def schema
      return unless @schema_name
      Dynamic::Schema.includes(Dynamic::Schema.includes_for_load).find_from_cache(@schema_name)
    end
  end
end
