# frozen_string_literal: true

class AddNpaiToKnewsletterFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::Knewsletter::Feature')
      next unless feature&.enabled?

      newsletter_klass_name = feature.options.find_by(name: 'newsletter_klass_name')&.value || 'Newsletter'
      newsletter_schema_klass = schema.klasses.find_by(name: newsletter_klass_name)
      next unless newsletter_schema_klass

      create_npai_attributes_if_missing!(newsletter_schema_klass)
      # backfill_npai_values!(schema, newsletter_schema_klass)
    end
  end

  def down
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::Knewsletter::Feature')
      next unless feature

      newsletter_klass_name = feature.options.find_by(name: 'newsletter_klass_name')&.value || 'Newsletter'
      newsletter_schema_klass = schema.klasses.find_by(name: newsletter_klass_name)
      next unless newsletter_schema_klass

      newsletter_schema_klass.attrs.where(name: %w[npai npai_percentage]).destroy_all
    end
  end

  private

  def create_npai_attributes_if_missing!(newsletter_schema_klass)
    ensure_float_attribute!(newsletter_schema_klass, 'npai', 'Nombre de NPAI', 'NPAI count')
    ensure_float_attribute!(newsletter_schema_klass, 'npai_percentage', 'Taux NPAI', 'NPAI rate')
  end

  def ensure_float_attribute!(newsletter_schema_klass, name, human_name_fr, human_name_en)
    attrs_scope = newsletter_schema_klass.attrs
    return if attrs_scope.where(name: name).exists?

    deleted_attrs = attrs_scope.only_deleted
      .where(name: name)
      .order(updated_at: :desc)
      .to_a

    deleted_attr = deleted_attrs.first

    if deleted_attr
      duplicate_deleted_ids = deleted_attrs.drop(1).map(&:id)
      attrs_scope.with_deleted.where(id: duplicate_deleted_ids).delete_all if duplicate_deleted_ids.any?

      deleted_attr.update!(
        deleted_at: nil,
        type: 'Float',
        updated_at: Time.current
      )
      return
    end

    attrs_scope.create!(
      name: name,
      human_name_fr: human_name_fr,
      human_name_en: human_name_en,
      type: 'Float'
    )
  rescue ActiveRecord::RecordInvalid => e
    details = e.record&.errors&.details || {}
    limit_exceeded = details[:column]&.any? { |d| d[:error].to_s == 'limit_exceeded' }
    raise e unless limit_exceeded

    Rails.logger.warn(
      "Skip NPAI attribute '#{name}' for schema_klass #{newsletter_schema_klass.id} (column limit_exceeded)"
    )
  end

  def backfill_npai_values!(schema, newsletter_schema_klass)
    schema.load
    newsletter_klass = newsletter_schema_klass.const
    has_npai_attr = newsletter_klass.dynamic_mapping.has_key?('npai')
    has_npai_percentage_attr = newsletter_klass.dynamic_mapping.has_key?('npai_percentage')
    return unless has_npai_attr || has_npai_percentage_attr

    recipients_association = newsletter_klass.reflect_on_association(:recipients)
    return unless recipients_association

    recipient_klass = recipients_association.klass
    assoc_klass = schema.const_assoc_klass

    association_scope = assoc_klass.where(
      association_owner_type: newsletter_klass.name,
      association_target_type: recipient_klass.name,
    )

    newsletter_klass.in_batches(of: 1000) do |batch|
      newsletter_ids = batch.pluck(:id)
      metrics_by_newsletter = metrics_by_newsletter_id(
        association_scope.where(association_owner_id: newsletter_ids),
        assoc_klass,
        recipient_klass,
      )
      next if metrics_by_newsletter.nil?

      batch.each do |newsletter|
        metrics = metrics_by_newsletter[newsletter.id] || {}
        recipients_count = metrics[:recipients_count] || 0
        npai_count = metrics[:npai_count] || 0

        npai_rate = if recipients_count > 0
          [(npai_count.to_f * 100.0 / recipients_count), 100.0].min
        else
          0.0
        end

        updates = {}
        updates[:npai] = npai_count if has_npai_attr
        updates[:npai_percentage] = npai_rate if has_npai_percentage_attr
        next if updates.empty?

        newsletter.update!(updates)
      end
    end
  end

  def metrics_by_newsletter_id(association_scope, assoc_klass, recipient_klass)
    assoc_table = assoc_klass.table_name
    recipient_table = recipient_klass.table_name
    info_association = recipient_klass.reflect_on_association(:info)
    return nil unless info_association

    info_klass = info_association.klass
    return nil unless info_klass.dynamic_mapping.has_key?('npai')

    info_table = info_klass.table_name
    info_npai_column = info_klass.dynamic_mapping['npai']
    recipient_primary_key = recipient_klass.primary_key

    joined_scope = association_scope.joins(
      "INNER JOIN #{recipient_table} recipients_join ON recipients_join.id = #{assoc_table}.association_target_id"
    )
    joined_scope = joined_scope.joins(
      <<~SQL.squish
        INNER JOIN #{assoc_table} recipient_info_assoc_join
          ON recipient_info_assoc_join.association_owner_type = '#{recipient_klass.name}'
         AND recipient_info_assoc_join.association_target_type = '#{info_klass.name}'
         AND recipient_info_assoc_join.association_owner_id = recipients_join.#{recipient_primary_key}
      SQL
    )
    joined_scope = joined_scope.joins(
      "INNER JOIN #{info_table} recipient_infos_join ON recipient_infos_join.id = recipient_info_assoc_join.association_target_id"
    )

    rows = joined_scope
      .group(:association_owner_id)
      .pluck(
        :association_owner_id,
        Arel.sql("COUNT(DISTINCT #{assoc_table}.association_target_id)"),
        Arel.sql("COUNT(DISTINCT CASE WHEN recipient_infos_join.#{info_npai_column} = TRUE THEN #{assoc_table}.association_target_id END)")
      )

    rows.each_with_object({}) do |(newsletter_id, recipients_count, npai_count), acc|
      acc[newsletter_id] = {
        recipients_count: recipients_count.to_i,
        npai_count: npai_count.to_i,
      }
    end
  end
end
