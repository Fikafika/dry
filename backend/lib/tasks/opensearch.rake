namespace :opensearch do

  desc "Destroy all opensearch indices"
  task destroy_all_indices: :environment do
    destroy_all_indices
  end

  desc "Create all opensearch indices"
  task create_all_indices: :environment do
    create_all_indices
  end

  desc "Index all records"
  task index_all: :environment do
    put_os_permissions
    index_all_active_records
    index_all_records_of_reserved_tables
    index_all_dynamic_records
  end

  desc "Re-create all indices and index all records"
  task recreate_and_index_all: :environment do
    destroy_all_indices
    create_all_indices
    put_os_permissions
    index_all_active_records
    index_all_records_of_reserved_tables
    index_all_dynamic_records
  end

  private

  def destroy_all_indices
    OpenSearch::Model.client.indices.get(index: '*').keys.each do |index|
      next if index.start_with?('.') # .opendistro_security, .tasks ...
      OpenSearch::Model.client.indices.delete(index: index)
    end
  end

  def create_all_indices
    uneek_sso_client_sync_all
    UneekPermission::PredefinedReceiver::Public.instance.__opensearch__.index_document # create index automatically
    Dynamic::Schema::Option::Base.where(name: 'elasticsearch_indices_already_created').find_each do |option|
      option.value = false
      option.save!(touch: false)
    end
    Dynamic::Schema::Klass.find_each do |k|
      k.elasticsearch_updated_at = nil,
      k.save!(touch: false)
    end
    Dynamic::Schema.find_each do |s|
      s.unload
      s.load # features with elasticsearch_indices_already_created option should recreate their index
      s.klasses.each do |k|
        k.update_elasticsearch_index
      end
    end
  end

  def uneek_sso_client_sync_all
    puts "SSO sync all"
    UneekSsoClient.sync_all! # create users, roles indices
  end

  def index_all_active_records
    UneekSsoClient.sync_all!
    [
      User,
      Role,
      UneekPermission::PredefinedReceiver::Public,
    ].each do |k|
      index_all_records_of_klass(k)
    end
  end

  def put_os_permissions
    Role.where(admin: false).all.each(&:put_os_role)
    User.where(super_admin: false).find_each do |r|
      r.put_os_user
    end
    UneekPermission::Rule.find_each do |r|
      next unless r.eligible_as_opensearch_rule?
      r.send(:update_opensearch_permissions)
    end
  end

  def index_all_records_of_klass(klass)
    require 'progress_bar'
    count = klass.count
    bar = ProgressBar.new(count, :bar, :rate, :eta)
    bar.puts "#{klass.name} (#{count})"
    klass.find_in_batches(:batch_size => 100) do |g|
      begin
        OpenSearch::Model.bulk(g)
      rescue => e
        bar.puts "#{g.first.class.name}-#{g.first.id}"
        bar.puts e.message
      end
      bar.increment!(g.length)
    end
  end

  def index_all_dynamic_records
    require 'progress_bar'
    Dynamic::Schema.find_each do |s|
      s.load
      count = s.klasses.sum{|k| k.const.count}
      bar = ProgressBar.new(count, :bar, :rate, :eta)
      bar.puts "D::#{s.name}::* (#{count})"
      s.klasses.each do |k|
        klass = k.const
        if klass.respond_to?(:as_deep_json_options_to_preload_options_includes)
          preloads = klass.as_deep_json_options_to_preload_options_includes(klass.options_for_indexed_json.merge(secure: false))
        else
          preloads = klass.try(:preload_for_dependency)
        end
        klass.preload(preloads).find_in_batches(:batch_size => 100) do |g|
          begin
            OpenSearch::Model.bulk(g)
          rescue => e
            bar.puts "#{g.first.class.name}-#{g.first.id}"
            bar.puts e.message
          end
          bar.increment!(g.length)
        end
      end
    end
  end

  def index_all_records_of_reserved_tables
    Dynamic::Schema.find_each do |s|
      s.load
      travel_in_constants(s.reserved) do |c|
        next unless c < OpenSearch::Model
        index_all_records_of_klass(c)
      end
    end
  end

  def travel_in_constants(mod, done = Set.new, &block)
    return if done.include?(mod)
    done << mod
    mod.constants.each do |c|
      next if c.in?([
        :ClassMethods,
      ])
      d = mod.const_get(c) rescue nil
      case d
      when ::Module
        yield(d)
        travel_in_constants(d, done, &block)
      end
    end
  end

end
