# frozen_string_literal: true

require 'progress_bar'

class DataAddSourceAndTargetRecordToDynamicFormSubmissions < ActiveRecord::Migration[6.0]
  def up
    scope = Dynamic::Form::Submission
    progress = ProgressBar.new(scope.count)
    batch_size = 100
    scope.find_in_batches(batch_size: batch_size) do |b|
      b.each do |s|
        next unless s.params
        s.source_record_id = s.params.dig(:where, :"source_record_id") || s.params[:"source_record_id"]
        s.source_record_type = s.params.dig(:where, :"source_record_type") || s.params[:"source_record_type"]
        s.target_record_id = s.params.dig(:where, :"target_record_id") || s.params[:"target_record_id"]
        s.target_record_type = s.params.dig(:where, :"target_record_type") || s.params[:"target_record_type"]

        s.source_record_id = nil unless s.source_record_id.present?
        s.source_record_type = nil unless s.source_record_type.present?
        s.target_record_id = nil unless s.target_record_id.present?
        s.target_record_type = nil unless s.target_record_type.present?

        s.save if s.changed?
      end
      progress.increment!(batch_size)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
