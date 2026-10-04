class Api::Dynamic::Record::VersionsController < Api::Dynamic::BaseController
  include LoadSchema

  prepend_around_action :load_schema

  prepend_before_action :forbidden, unless: :current_user_is_admin?

  private

  def schema_name
    @schema_name ||= params[:schema_name].classify_permalink
  end

  def forbidden
    raise Forbidden.new
  end

  def scope
    s = klass
    if record_id && record_klass
      s = s.where(item_id: record_id, item_type: record_klass.base_class.name).includes(item: {}, source: {translations: {}}, author: {})
    else
      s = s.none
    end
    s
  end

  def record_id
    params[:id]
  end

  def klass
    @klass ||= "#{record_klass.name}Version".constantize
  end

  def record_klass
    @record_klass ||= "D::#{schema_name}".constantize.const_get_by_route_key(params[:klass_name])
  end

  def deep_json_options
    {
      only: ['id', 'event', 'created_at'],
      include: {
        changeset: {},
        data_for_changeset: {},
        source: {
          only: ['human_name', 'url'],
          include: {
            class: {as: 'type'},
            translations: {
              only: ['locale', 'human_name']
            },
          }
        },
        author: {
          only: ['first_name', 'last_name', 'login'],
        }
      },
      secure: false,
    }
  end

  def elements
    preload_data_for_changeset(super)
  end

  def preload_data_for_changeset(versions) # assign name and photo of associated records to version
    define_data_for_changeset(versions)
    ids_by_klass, versions_by_record_id, signed_ids, versions_by_signed_id = extract_ids_from_changesets(versions)
    preload_associated_records(ids_by_klass, versions_by_record_id)
    preload_associated_blobs(signed_ids, versions_by_signed_id)
    return versions
  end

  def define_data_for_changeset(versions)
    versions.each do |v|
      v.instance_variable_set(:@data_for_changeset, {})
      def v.data_for_changeset
        @data_for_changeset
      end
    end
  end

  def extract_ids_from_changesets(versions)
    ids_by_klass = {}
    versions_by_record_id = {}
    signed_ids = Set.new
    versions_by_signed_id = {}

    versions.each do |v|
      v.changeset.each do |attr, change|
        if reflection = record_klass.reflect_on_association_from_method_name(attr)
          target_klass = (reflection.klass rescue nil)

          if attr.end_with?('_id')
            change.each do |id|
              next unless id
              ids_by_klass[target_klass] ||= Set.new
              ids_by_klass[target_klass] << id
              versions_by_record_id[id] ||= Set.new
              versions_by_record_id[id] << v
            end
          elsif attr.end_with?('_ids')
            ['added', 'removed'].each do |k|
              change[k]&.each do |id|
                next unless id
                ids_by_klass[target_klass] ||= Set.new
                ids_by_klass[target_klass] << id
                versions_by_record_id[id] ||= Set.new
                versions_by_record_id[id] << v
              end
            end
          end
        elsif reflection = record_klass.reflect_on_attachment(attr)
          case change
          when Array
            change.each do |s|
              next unless s
              signed_ids << s
              versions_by_signed_id[s] ||= Set.new
              versions_by_signed_id[s] << v
            end
          when Hash
            ['added', 'removed'].each do |k|
              change[k]&.each do |s|
                next unless s
                signed_ids << s
                versions_by_signed_id[s] ||= Set.new
                versions_by_signed_id[s] << v
              end
            end
          end
        end
      end
    end
    return ids_by_klass, versions_by_record_id, signed_ids, versions_by_signed_id
  end

  def preload_associated_records(ids_by_klass, versions_by_record_id)
    record_by_id = {}
    ids_by_klass.each do |klass, ids|
      next unless ids.any?

      klasses = klass ? [klass] : target_klasses_of_polymoprhic_associations

      klasses.each do |klass|
        selected_columns = ['id', 'type']
        name_attribute = klass.name_attribute
        if name_attribute && !name_attribute.in?(klass.dynamic_translated_attribute_names)
          d = klass.dynamic_mapping[name_attribute] # TODO dynamic_record should add corresponding dynamic_attributes
          selected_columns << d if d
        end
        records = []
        klass.where(id: ids).select(*selected_columns).find_each do |record|
          record_by_id[record.id] = record
          records << record
        end
        if records.any? && klass.photo_attachment
          if klass.reflect_on_attachment(klass.photo_attachment).macro == :has_many_attached
            preload_attachment_associations = [:"#{klass.photo_attachment}_blobs", :"#{klass.photo_attachment}_attachments"]
          else
            preload_attachment_associations = [:"#{klass.photo_attachment}_blob", :"#{klass.photo_attachment}_attachment"]
          end
          ActiveRecord::Associations::Preloader.new(records: records, associations: preload_attachment_associations).call
        end
      end
    end

    versions_by_record_id.each do |id, versions_|
      versions_.each do |v|
        record = record_by_id[id]
        next unless record # some can be missing because they are deleted
        v.data_for_changeset[id] = record.as_deep_json(as_deep_json_options_for_associated_records(record.class))
      end
    end
  end

  def target_klasses_of_polymoprhic_associations
    return @target_klasses_of_polymoprhic_associations if @target_klasses_of_polymoprhic_associations
    schema_association_ids = record_klass.reflect_on_all_associations.select(&:polymorphic?).map(&:schema_association_id)
    @target_klasses_of_polymoprhic_associations = @schema.const::DynamicAssociation.where(
      schema_association_id: schema_association_ids,
      association_owner_id: record_id
    ).select(:association_target_type).distinct.pluck(:association_target_type).map(&:safe_constantize).compact

    @target_klasses_of_polymoprhic_associations
  end

  def as_deep_json_options_for_associated_records(record_class) # TODO it should be defined somewhere else (predefined includes ?)
    r = { only: ['id', 'type'], include: {}, secure: false }
    r[:only] << record_class.name_attribute if record_class.try(:name_attribute)
    if record_class.try(:photo_attachment)
      r[:include][record_class.photo_attachment] = active_storage_includes(record_class.reflect_on_attachment(record_class.photo_attachment).macro)
    end
    r
  end

  def active_storage_includes(macro)
    {
      include: {
        :"attachment#{'s' if macro == :has_many_attached}" => {
          only: [],
          include: {
            signed_id: 1,
            filename: 1,
            blob: {
              only: [
                'content_type',
                'byte_size',
                'checksum',
              ],
              include: {
                signed_id: 1,
                filename: 1,
                only: [],
              },
            },
          },
        },
      },
    }
  end

  def preload_associated_blobs(signed_ids, versions_by_signed_id)
    signed_id_by_blob_id = {}
    signed_ids.each do |signed_id|
      key = ActiveStorage::Blob.signed_id_verifier.verify(signed_id, purpose: :blob_id)
      signed_id_by_blob_id[key] = signed_id
    end

    ActiveStorage::Blob.where(id: signed_id_by_blob_id.keys).find_each do |blob|
      signed_id = signed_id_by_blob_id[blob.id]
      versions_by_signed_id[signed_id].each do |v|
        v.data_for_changeset[signed_id] = {
          checksum: blob.checksum,
          byte_size: blob.byte_size,
          content_type: blob.content_type,
          filename: blob.filename,
        }
      end
    end
  end
end
