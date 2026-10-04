module Dynamic
  module Record
    class SubmitAllWorker < BulkWorker
      def apply(batch)
        ::ModelDependency.with_dependencies_computed_later do
          block_for_process = on_conflict_element ? method(:process_deduplication) : nil
          process_batch(batch, &block_for_process)
        end
      end

      def process_batch(batch, &block)
        batch.each do |record|
          form.target_record = record
          success = if block_given?
            yield
          else
            success = form.submit(form_params)
          end
          form.reset
          update_progress(success: success, instant: record == batch.first)
          break if progress&.canceled?
        end
      end

      def process_deduplication
        success = false
        batch_id = form_params[:batch_id]
        raise ArgumentError, 'Missing batch_id when deduplicating submissions' unless batch_id
        form.load_and_build_records
        form.target_record.reload # Reloading to remove any records build in associations

        duplicates = find_duplicates(batch_id)

        success = if duplicates.none?
          form.submit(form_params.deep_dup)
        else
          duplicated_record = duplicates.first.submission_records.first.record
          form.target_record.association(form.association.name).add_without_save(duplicated_record)
          form.target_record.save
          form.elements.each do |e|
            next unless e.type == 'Association::HasMany'
            next unless e.default_value_formula && e.record_type_for_default_value_formula == 'target_record'
            e.force_default_value = true
            e.compute_formula_with_record(duplicated_record)
            e.force_default_value = false
          end
          duplicated_record.save
        end

        return success
      end

      def find_duplicates(batch_id)
        current_record = form.record_for_element(on_conflict_element)

        reflection = current_record.class.reflect_on_association(on_conflict_element.attribute_name)
        if reflection
          version_attr_name = "#{on_conflict_element.attribute_name}_id"
          case reflection.macro
          when :has_one, :belongs_to
            value = current_record.try(on_conflict_element.attribute_name)&.id
          end
        else
          version_attr_name = on_conflict_element.attribute_name
          value = current_record.try(on_conflict_element.attribute_name)
        end

        relation = form.submissions.where(batch_id: batch_id).joins(:submission_records)

        submission_record_table = Dynamic::Form::SubmissionRecord.arel_table
        target_table = current_record.class.arel_table
        target_version_table = "#{current_record.class.name}Version".constantize.arel_table
        # This operator is only present in Postgresql
        value_found_in_object_changes = Arel::Nodes::InfixOperation.new('#>>', target_version_table[:object_changes], Arel::Nodes.build_quoted("{#{version_attr_name},1}").eq(value))

        deduplicate_version_join = submission_record_table.join(
          target_table).on(submission_record_table[:record_id].eq(target_table[:id])
        ).join(
          target_version_table
        ).on(
          target_table[:id].eq(target_version_table[:item_id]).and(
            target_version_table[:event].eq('create')
          ).and(
            value_found_in_object_changes
          )
        )

        return relation.joins(deduplicate_version_join.join_sources).all
      end

      def form
        @form ||= Dynamic::Form.find(perform_params[:form_id])
      end

      def form_params
        perform_params[:form_params]
      end

      def on_conflict_element
        return @on_conflict_element if @on_conflict_element
        element_id = perform_params[:on_conflict_element_id]
        return nil unless element_id
        @on_conflict_element = form.elements.detect {|e| e.id == element_id}
      end

      def additional_progress_errors
        progress.errors << {form: :blank} unless form
        progress.errors << {form_params: :blank} unless form_params
      end

    end
  end
end