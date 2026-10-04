class Crm
  class Import
    module Step
      class Deduplication < Base

        before_render do
          if source.present? && source.klass_name
            setup_deduplication
          end
        end

        render do
          content if setting.loaded?
        end

        module Initialization; extend ActiveSupport::Concern
          def init_deduplication_keys(klass = source.klass_name&.constantize)
            return unless klass
            if @deduplication_keys.nil?
              @deduplication_keys = {}
              source.cascades.each do |cascade|
                k = cascade.klass_name&.safe_constantize
                next unless k
                a = k.reflect_on_association(cascade.association_name)
                @deduplication_keys[{ klass: k, assoc: a }] = {keys: cascade.keys , count: {}, cascade: cascade}
              end
              source.columns.each do |col|
                next unless col.path&.any?
                increment_count_attribute(col.path)
              end
              @deduplication_keys[{ klass: klass, assoc: nil }] ||= { keys: [], count: {}, cascade: nil }
            end
          end

          def increment_count_attribute(path)
            return unless path
            p = klass_and_assoc_from_path(path)
            @deduplication_keys[p] ||= {keys: [], count: {}}
            @deduplication_keys[p][:count][path.last] ||= 0
            @deduplication_keys[p][:count][path.last] += 1
          end

          def klass_and_assoc_from_path(path)
            k = source.klass_name&.safe_constantize
            return nil unless k
            a = nil
            last_klass = k
            last_assoc = a
            (1..path.count).step(2) do |i|
              a = k.reflect_on_association(path[i])
              break unless a
              association = k.reflect_on_association(a.name)
              @deduplication_keys[{ klass: k, assoc: association }] ||= { keys: [], count: {}, cascade: nil }
              last_assoc = a
              last_klass = k
              k = a.klass
            end
            return { klass: last_klass, assoc: last_assoc }
          end

          def setup_deduplication
            k = source.klass_name.constantize
            init_deduplication_keys
            @attrs_or_assocs_by_klass ||= {}
            unless @attrs_or_assocs_by_klass.present?
              extract_method_names(k)
            end
            unless @base_klass_attrs_or_assocs.present?
              extract_all_assoc_mapped(k)
            end
          end
        end; include Initialization

        module AttributeExtraction; extend ActiveSupport::Concern
          def extract_method_names(klass)
            method_names = {}
            source.columns.each do |column|
              process_column(klass, column, method_names)
            end
            extract_attrs(method_names)
          end

          def extract_attrs(method_names)
            @deduplication_keys&.each do |path, element|
              next unless path[:assoc]
              key_to_check = build_key_from_hash(path)
              attrs = process_association_path(path, method_names)
              @attrs_or_assocs_by_klass[key_to_check] ||= Set.new
              @attrs_or_assocs_by_klass[key_to_check] += attrs
            end
            @attrs_or_assocs_by_klass
          end

          def build_key_from_hash(hash)
            build_key(hash[:klass], hash[:assoc].klass, hash[:assoc].name)
          end

          def build_key(owner_klass, target_klass, association_name)
            "#{owner_klass.base_class.name}::#{target_klass&.base_class&.name}-#{association_name}"
          end

          def extract_all_assoc_mapped(klass)
            @base_klass_attrs_or_assocs ||= Set.new
            source.columns.each do |item|
              next unless item.respond_to?(:method_names)
              @base_klass_attrs_or_assocs << item.method_names.first
            end
            klass.reflect_on_all_associations.each do |assoc|
              method_name_assoc = assoc.name.to_s
              @attrs_or_assocs_by_klass ||= {}
              @attrs_or_assocs_by_klass[klass.to_s] ||= Set.new
              if @attrs_or_assocs_by_klass[klass.to_s].include?(method_name_assoc)
                @base_klass_attrs_or_assocs << method_name_assoc
              end
            end
            @base_klass_attrs_or_assocs
          end
        end; include AttributeExtraction

        module ColumnProcessing; extend ActiveSupport::Concern
          def process_column(klass, column, method_names)
            klass_name = klass.name.to_s
            @current_class = klass
            @prev_class  = klass
            method_names[klass_name] ||= []
            return if column.method_names.count <= 1
            associations = column.method_names[0...-1]
            attribute = column.method_names[-1]
            last_assoc = associations[-1]
            default_params = {
              klass: klass,
              method_names: method_names,
              associations: associations,
              current_class: @current_class,
              attribute: attribute
            }
            associations.each_with_index do |assoc_name, index|
              assoc = @current_class.reflect_on_association(assoc_name)
              params_assoc = default_params.merge({
                assoc_name: assoc_name,
                index: index,
                current_klass: @current_class,
                assoc: assoc
              })
              add_association(params_assoc)
              # add intermediate associations
              if index < associations.length - 1
                next_assoc = associations[index + 2]
                if associations.length <= 3 || next_assoc
                  add_special_association(params_assoc)
                end
              end
              @prev_class = @current_class
              @current_class = assoc.klass
            end
            params_attrs = default_params.merge({
              prev_class: @prev_class,
              current_class: @current_class,
              last_assoc: last_assoc
            })
            add_attr(params_attrs)
          end

          def process_association_path(path, method_names)
            attrs = Set.new
            key_to_check = build_key_from_hash(path)
            klass_name = source.klass_name
            nested_hash = method_names[klass_name]
            if nested_hash
              found_hashes = nested_hash.select { |hash| hash.has_key?(key_to_check) }
              attrs.merge(process_found_hashes(found_hashes, key_to_check))
            end
            attrs
          end

          def process_found_hashes(found_hashes, key_to_check)
            attrs = Set.new
            found_hashes.each do |found_hash|
              if found_hash.dig(key_to_check, 'attrs')&.any?
                found_hash[key_to_check]['attrs'].each do |attr|
                  attrs << attr.to_s.downcase
                end
              elsif found_hash.dig(key_to_check, 'next_method')
                attrs << found_hash[key_to_check]['next_method'].to_s.downcase
              end
              if found_hash.dig(key_to_check, 'associations')&.any?
                found_hash[key_to_check]['associations'].each do |attr|
                  attrs << attr.to_s.downcase
                end
              end
              if found_hash.dig(key_to_check, 'inverse_of')
                attrs << found_hash[key_to_check]['inverse_of'].to_s.downcase
              end
            end
            attrs
          end
        end; include ColumnProcessing

        module AssociationHelpers; extend ActiveSupport::Concern
          def add_association(klass:, assoc_name:, method_names:, current_klass:, index:, associations:)
            klass_name = klass.name.to_s
            assoc = current_klass.reflect_on_association(assoc_name)
            next_assoc = current_klass.reflect_on_association(associations[index + 1])
            next_assoc_name = associations[index + 1]
            if assoc
              assoc_klass_name = assoc.klass&.name.to_s
              klass_name_owner = assoc.instance_variable_get(:@owner_klass).to_s
            elsif next_assoc
              assoc_klass_name = next_assoc.klass&.name.to_s
              inverse_assoc = next_assoc.klass.reflect_on_association(next_assoc.options[:inverse_of].to_s)
              klass_name_owner = inverse_assoc.klass.to_s
            end
            association_key = build_association_key(
              klass_name: klass_name,
              assoc: assoc,
              previous_klass_name: assoc_klass_name,
              klass_name_owner: klass_name_owner,
              assoc_name: assoc_name,
            )
            if assoc
              method_names[klass_name] << { association_key => { "associations" => Set.new([next_assoc_name]) } }
            else
              method_names[klass_name] << { association_key => { "associations" => Set.new } }
            end
            current_entry = method_names[klass_name][-1] if method_names[klass_name].any?
            if current_entry && current_entry[association_key]
              assoc_next = assoc_klass_name&.safe_constantize&.reflect_on_association(assoc_name)
              if assoc&.options && assoc.options[:inverse_of]
                current_entry[association_key]["inverse_of"] = assoc.options[:inverse_of].to_s
              end
              if assoc_next&.options&.dig(:inverse_of) && assoc&.options && assoc.options[:inverse_of] != assoc_next.options[:inverse_of]
                current_entry[association_key]["inverse_of"] = assoc_next.options[:inverse_of].to_s
              end
              if next_assoc && associations.length > 1
                current_entry[association_key]["next_method"] = current_klass.human_attribute_name(next_assoc_name.to_s.downcase)
              end
            end
          end

          def build_association_key(klass_name:, assoc:, previous_klass_name:, assoc_name:, klass_name_owner:)
            prefix = klass_name_owner ? klass_name_owner : klass_name
            suffix = assoc ? previous_klass_name : klass_name
            build_key(prefix.safe_constantize, suffix.safe_constantize, assoc_name)
          end

          def add_special_association(klass:, method_names:, assoc_name:, associations:, attribute:, index:)
            return unless assoc_name
            klass_name = klass.name.to_s
            assoc_owner = associations[index + 1]
            next_assoc = associations[index + 2]
            target_klass = klass.reflect_on_association(assoc_name)&.klass
            assoc_class_name = target_klass ? target_klass.base_class.name : assoc_name&.capitalize
            association_key = "#{assoc_class_name}::#{klass.base_class.name}-#{assoc_owner}"
            val = next_assoc ? next_assoc : attribute
            method_names[klass_name] << { association_key => { 'associations' => Set.new([val]) } }
          end

          def add_attr(prev_class:, last_assoc:, current_class:, method_names:, klass:, attribute:)
            association_key = build_key(prev_class, @current_class, last_assoc)
            entry = method_names[klass.name.to_s].find { |hash| hash.key?(association_key) }
            if entry
              entry[association_key]['attrs'] ||= Set.new
              entry[association_key]['attrs'].add(attribute)
            end
          end
        end; include AssociationHelpers

        def content
          DIV(class: 'd-flex flex-column pt-5 mt-5') do
            H4(class: 'mt-3') do
              SPAN do
                I18n.t("crm.import.settings.table.object_duplication_keys")
              end
            end
            DIV(class: 'd-flex flex-row') do
              DIV(class: 'flex-column') do
                DIV do
                  I18n.t('crm.import.settings.table.name') + ' : '
                end
                DIV do
                  I18n.t('crm.import.settings.table.file') + ' : '
                end
              end
              DIV(class: 'flex-column ml-3') do
                DIV do
                  setting.name
                end
                DIV do
                  if source.try(:csv)&.attached?
                    file = source.original_csv
                    A(href: file.download_path) do
                      I(class:'fa fa-download')
                      SPAN(class: 'ml-1') do
                        file&.filename
                      end
                    end
                  else
                    I18n.t('crm.import.settings.no_file')
                  end
                end
              end
            end
            if source.klass_name
              klass = source.klass_name&.constantize
              @deduplication_keys&.each do |path, element|
                k = source.klass_name&.safe_constantize
                render_path_view(path)
                klass = path[:assoc]&.klass || path[:klass]
                attrs = gather_attrs(path, klass, k)
                handle_deduplication(klass, element, attrs)
              end
            end
          end
          footer
          scroll_to_top_button
        end

        def render_path_view(path)
          DIV(class: 'd-flex flex-row') do
            SPAN(class: 'h5 mb-0') do
              path[:klass]&.model_name&.human
            end
            if path[:assoc]
              I(class: 'mx-1 align-self-center fa fa-chevron-right fa-fw')
              SPAN(class: 'h5 mb-0') do
                path[:klass].human_attribute_name(path[:assoc].name)
              end
            end
          end
        end

        def handle_deduplication(klass, element, attrs)
          DeduplicationKeys(
            klass: klass,
            keys: element[:keys],
            attrs: attrs,
            mapped_attrs: attrs,
            clean_unknown_attrs: true,
          ).on(:change) do |keys|
            element[:keys] = keys
          end
        end

        def gather_attrs(path, klass, base_klass)
          path[:assoc] ? @attrs_or_assocs_by_klass[build_key_from_hash(path)] : @base_klass_attrs_or_assocs
        end

        def process_action_before_saving
          apply_deduplication_keys
        end

        def process_action_on_success
          @deduplication_keys = nil
          init_deduplication_keys
        end

        def process_cancel_button(event)
          setting.reload do |response|
            @setting = nil
            source = nil
            @deduplication_keys = nil
            mutate
          end
        end

        def apply_deduplication_keys
          @deduplication_keys.each do |path, element|
            if element[:cascade]
              element[:cascade].keys = element[:keys]
            else
              source.cascades.new({
                klass_name: path[:klass].name,
                association_name: path[:assoc]&.name,
                keys: element[:keys],
              })
            end
          end
        end

        def setting_includes
          {
            include: {
              output: {
                include: {
                  cascades: {
                    include: {
                      klass_name: 1,
                      association_name: 1,
                      keys: 1,
                    }
                  },
                  columns: 1,
                  csv: csv_includes,
                  original_csv: csv_includes,
                }
              }
            },
          }
        end

        def object_to_save
          source.save
        end

        def source
          setting.output
        end

      end
    end
  end
end
