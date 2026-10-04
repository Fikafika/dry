#!/usr/local/bin/ruby

#
# this script can be used to import data exported with /var/www/beta/core/current/tools/dynamo_exporter.rb
#

require File.expand_path('../../config/environment', __dir__)
require 'progress_bar'

class CoreImporter

  attr_accessor :importer_options

  def initialize(schema_name, options = {})
    @schema_name = schema_name
    @schema = Dynamic::Schema.where(name: @schema_name).first
    @importer_options = options
    @importer_options[:progress] = true unless @importer_options.has_key?(:progress) || @importer_options[:verbose]
    @src = options[:src] || "tmp/#{@schema_name.underscore}"
    @start_after = options[:start_after]
    @start = false
  end

  def import_schema
    puts "import schema"
    json = JSON.parse(File.read("#{@src}/schema.json"))
    ::Sidekiq::Worker.throttle(:admin) do
      if @schema.nil? && @importer_options[:create]
        @schema = Dynamic::Schema.create!(json)
        unless Rails.env.production?
          UneekSsoClient.sync_all!
          community = Community.where(schema: @schema).find_or_create_by!(schema_id: @schema.id, name: @schema.name, permalink: @schema.name.underscore) # correct permalink ?
          User.where(login: 'contact@kosmopolead.com').first&.memberships&.create(community: community, admin: true)
        end
      else
        @schema.update!(json.except('id'))
      end
    end
    @schema.reload
  end

  def import_attachments(reload = true)
    return unless @reload || !@attachment_imported
    ActiveStorage::Blob.transaction do
      Dir.each_child("#{@src}/attachments") do |blob_id|
        next unless blob_id =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
        next if ActiveStorage::Blob.exists?(blob_id)
        Dir.each_child("#{@src}/attachments/#{blob_id}") do |filename|
          blob = ActiveStorage::Blob.create_and_upload!(io: File.new("#{@src}/attachments/#{blob_id}/#{filename}"), filename: filename)
          blob.id = blob_id
          blob.save!
          break
        end
      end
    end
    @attachment_imported = true
  end

  def import_klass(klass_name, do_reload_schema = true, compute_formula_later = true, skip_associations = false)
    import_attachments(false)
    reload_schema if do_reload_schema

    full_klass_name = "D::#{@schema.name}::#{klass_name.classify}"

    json_path = "#{@src}/#{full_klass_name.demodulize.underscore}.json"
    if File.exist?(json_path)
      puts "import #{full_klass_name}"
      with_formula_computed_later(compute_formula_later, klass_name) do
        klass = full_klass_name.safe_constantize
        raise "#{full_klass_name} doesn't exist" unless klass
        @bar = ProgressBar.new(%x{wc -l < "#{json_path}"}.to_i - 2) if importer_options[:progress]

        batch = []
        File.foreach(json_path).with_index do |line, line_num|
          next unless line.start_with?('{')
          line.gsub!(/,$/, '')
          attrs = JSON.parse(line)

          if skip_associations
            attrs.keys.each do |k|
              if k.ends_with?('_attributes')
                attrs.delete(k)
              end
            end
          end

          if @start_after
            if attrs['id'] == @start_after
              @start = true
            end
            next unless @start
          end
          batch << attrs
          if batch.length >= 1000
            import_batch(klass, batch)
            batch = []
          end
        end
        import_batch(klass, batch) if batch.any?
      end
    else
      puts "no file for #{full_klass_name}"
    end
  end

  def import_data
    reload_schema
    klasses = Dir["#{@src}/*.json"].sort
    with_formula_computed_later do
      klasses.each do |json_file|
        klass_name = json_file.gsub('.json', '').split('/').last&.classify
        next unless klass_name
        klass = "D::#{@schema.name}::#{klass_name}".safe_constantize
        next unless klass
        import_klass(klass_name, false, true, true) #on importe une première fois sans association pour ne pas que ça plante
      end
      klasses.each do |json_file|
        klass_name = json_file.gsub('.json', '').split('/').last&.classify
        next unless klass_name
        klass = "D::#{@schema.name}::#{klass_name}".safe_constantize
        next unless klass
        import_klass(klass_name, false, true, false) #on importe la deuxième fois avec associations
      end
    end
    return true
  end

  def compute_all_formulas(klass = nil) # TODO only dependent of klass
    Dynamic::Formula::Feature.compute_all(@schema, progress: true)
  end

  def delete_all_data
    reload_schema
    schema.klasses.each{|k| k.const.with_deleted.delete_all }
    schema.const::DynamicAssociation.with_deleted.delete_all
    ::OpenSearch::Model.client.indices.delete(index: '_all')
    schema.klasses.each{|k| puts k.name; k.update_elasticsearch_index }
    # TODO reindex User ?
  end

  private

  def import_batch(klass, batch)
    ModelDependency.with_dependencies_computed_later do
      ::Sidekiq::Worker.throttle(:admin) do
        batch.each do |attrs|
          attrs = attrs.reject{|k, v| !known_attrs(klass).include?(k.to_s) } if importer_options[:remove_unknown]
          puts attrs.inspect if importer_options[:verbose]
          r = klass.find_by_id(attrs['id'])
          begin
            if r
              if DateTime.parse(attrs['updated_at']) < r.updated_at
                puts "skip #{attrs['id']} because more recent in dynamo"
                next
              else
                r.update!(attrs)
              end
            else
              klass.create!(attrs)
            end
          rescue StandardError => e
            next if klass.with_deleted.find_by_id(attrs['id'])

            puts "#{klass.name} #{attrs.inspect}"
            puts e.message
          end
          @bar&.increment!
        end
      end
    end
  end

  def with_formula_computed_later(compute_formula_later = true, klass_name = nil)
    if compute_formula_later
      begin
        feature = @schema.features.detect{|f| f.name == 'Dynamic::Formula::Feature'}
        @was_enabled = feature.enabled?
        if @was_enabled
          feature.update!(enabled: false)
          reload_schema
        end
        yield
      ensure
        if @was_enabled
          feature.update(enabled: true)
          reload_schema
        end
      end
      klass = "D::#{@schema.name}::#{klass_name.classify}".safe_constantize
      compute_all_formulas(klass)
    else
      yield
    end
  end

  def known_attrs(klass)
    return @known_attrs[klass] if @known_attrs&.has_key?(klass)
    @known_attrs ||= {}
    @known_attrs[klass] = Set.new(klass.attribute_names + klass.reflect_on_all_associations.map(&:name).map{|e| "#{e}_attributes"} + ['attachments'] + klass.reflect_on_all_attachments.map{|a| a.name.to_s })
    return @known_attrs[klass]
  end

  def reload_schema
    @schema.unload; @schema.reload; @schema.load
  end
end

#importer = CoreImporter.new('Uneek', src: 'storage/uneek')
#importer.import_schema
#importer.import_data
#importer.import_klass('Contact')

# clean:
# root@sd-164629:~# rm -r /data/docker/volumes/dynamo_storage/_data/uneek
