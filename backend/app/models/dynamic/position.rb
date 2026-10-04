module Dynamic
  class Position < ActiveRecord::Base
    self.abstract_class = true

    include Dynamic::Mount

    define_table do |t|
      t.belongs_to :owner, type: :uuid, polymorphic: true
      t.uuid :context_value
      t.string :context_attr
      t.integer :value, null: false
    end

    after_mount do
      belongs_to :owner, polymorphic: true
      validates :value, presence: true
    end

    def self.create_missing(
      attr,
      source_value,
      target_value,
      moved,
      target,
      relation
    )

      source_position = find_by_record(moved, attr, source_value)

      target_position = target && find_by_record(target, attr, target_value)

      create_by_column(attr, source_value, relation) unless source_position.present?

      if source_value != target_value
        create_by_column(attr, target_value, relation) unless target_position.present?
      end
    end

    def self.create_by_column(attr, attr_value, relation)
      records = relation
        .where(attr => attr_value)
        .order(:id)

      return if records.empty?

      context_value = context_value(attr, attr_value, records.first.class)
      existing_owner_ids = self
        .where(context_attr: attr)
        .where(context_value: context_value)
        .map{|k| k.owner_id}
        .to_set

      next_position = self
        .where(context_attr: attr)
        .where(context_value: context_value)
        .count.to_i + 1

      positions = records.each_with_object([]) do |record, array|
        next if existing_owner_ids.include?(record.id)
        array << {
          owner_id: record.id,
          owner_type: relation.name,
          context_attr: attr,
          context_value: context_value,
          value: next_position,
        }
        next_position += 1
      end
      import(positions)
    end

    def self.find_by_record(record, attr, attr_value)
      self
        .where(owner: record)
        .where(context_attr: attr)
        .where(context_value: context_value(attr, attr_value, record.class))
        .first
    end

    def self.move_across_columns(attr, source_value, target_value, moved, target, dir)
      source_context_value = context_value(attr, source_value, moved.class)
      target_context_value = context_value(attr, target_value, moved.class)

      source_position = find_by_record(
        moved,
        attr,
        source_value
      )

      if source_position
        self
          .where(context_attr: attr)
          .where(context_value: source_context_value)
          .where('value > ?', source_position.value)
          .update_all(
            "value = value - 1, updated_at = '#{Time.current}'"
          )
      end

      new_value = new_value(
        attr,
        target_value,
        target,
        dir
      )

      self
        .where(context_attr: attr)
        .where(context_value: target_context_value)
        .where('value >= ?', new_value)
        .update_all(
          "value = value + 1, updated_at = '#{Time.current}'"
        )

      source_position.value = new_value
      source_position.context_value = target_context_value
      source_position.save!
      new_value
    end

    def self.move_within_column(attr, col_value, moved, target, dir)
      moved_position = find_by_record(moved, attr, col_value)

      old_value = moved_position.value || 0

      raw_target_value = new_value(attr, col_value, target, dir)

      new_value = raw_target_value

      if target
        target_position = find_by_record(target, attr, col_value)

        new_value -= 1 if target_position &&
          target_position.value > old_value
      end

      return old_value if new_value == old_value

      context_value = context_value(attr, col_value, moved.class)
      if new_value < old_value
        self
          .where(context_attr: attr)
          .where(context_value: context_value)
          .where(
            'value >= ? AND value < ?',
            new_value,
            old_value
          )
          .where.not(owner: moved)
          .update_all(
            "value = value + 1, updated_at = '#{Time.current}'"
          )
      else
        self
          .where(context_attr: attr)
          .where(context_value: context_value)
          .where(
            'value > ? AND value <= ?',
            old_value,
            new_value
          )
          .where.not(owner: moved)
          .update_all(
            "value = value - 1, updated_at = '#{Time.current}'"
          )
      end

      moved_position.value = new_value
      moved_position.save!
      new_value
    end

    def self.context_value(attr, value, klass)
      attr.end_with?('_id') ? value : klass.send("#{attr.pluralize}")[value]
    end

    def self.new_value(attr, col_value, target, dir)
      min = 1
      if target
        target_position = find_by_record(
          target,
          attr,
          col_value
        )
        base = target_position&.value || min
        dir == 'after' ? base + 1 : base
      else
        min
      end
    end
  end
end
