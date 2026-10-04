class Crm
  class Copy
    class Mapping < HyperComponent
      include ::SchemaLoading

      param :klass_name, default: nil
      param :mode, default: 'source'
      param :mapping_id, default: nil
      param :is_new, default: false
      param :back_location, default: nil

      FIXED_OPTION = '__fixed__'
      FORMULA_OPTION = '__formula__'

      render(DIV) do
        @render_cache = {}
        next unless schema&.constants_loaded?
        next unless record_ready?
        initialize_target_attrs_once
        initialize_has_many_rules_once
        ErrorMessage(record: record) if record.errors.present?
        header
        grid
        footer_buttons
      end

      def record_ready?
        return false unless record
        new_record? || record.loaded?
      end

      def new_record?
        is_new || mapping_id.blank?
      end

      def mapping_class
        schema.const::R::Copy::Mapping
      end

      def pair_class
        schema.const::R::Copy::Mapping::Pair
      end

      def has_many_rule_class
        schema.const::R::Copy::Mapping::HasManyRule
      end

      def cached(key)
        @render_cache ||= {}
        return @render_cache[key] if @render_cache.key?(key)
        @render_cache[key] = yield
      end

      def record
        cached(:record) { load_record }
      end

      def load_record
        if new_record?
          return @new_record if @new_record
          return nil unless schema&.constants_loaded?
          @new_record = mapping_class.new(
            source_klass_name: initial_source_klass_name,
            target_klass_name: initial_target_klass_name,
            name: '',
          )
        else
          observe mapping_class.includes(pairs: 1, has_many_rules: 1).find(mapping_id)
        end
      end

      def initial_source_klass_name
        mode == 'source' ? klass_name : nil
      end

      def initial_target_klass_name
        mode == 'target' ? klass_name : nil
      end

      def klass_by_id(id)
        return nil unless id && schema&.constants_loaded?
        klasses_by_id[id]
      end

      def klasses_by_id
        cached(:klasses_by_id) do
          schema.klasses.to_a.each_with_object({}) { |k, h| h[k.id] = k }
        end
      end

      def klass_by_name(name)
        return nil unless name && schema&.constants_loaded?
        klasses_by_name[name]
      end

      def klasses_by_name
        cached(:klasses_by_name) do
          schema.klasses.to_a.each_with_object({}) { |k, h| h[k.const_absolute_name] = k }
        end
      end

      def source_klass_record
        klass_by_name(record&.source_klass_name)
      end

      def target_klass_record
        klass_by_name(record&.target_klass_name)
      end

      def header
        DIV(class: 'mb-3') do
          DIV(class: 'form-group') do
            LABEL(class: 'font-weight-bold') { I18n.t('activerecord.attributes.dynamic/copy/mapping.name') }
            INPUT(type: 'text', class: 'form-control', value: record.name || '').on(:change) do |event|
              record.name = event.target.value
              mutate
            end
          end

          DIV(class: 'row') do
            klass_column('source')
            klass_column('target')
          end
        end
      end

      def klass_column(direction)
        DIV(class: 'col-6') do
          LABEL(class: 'font-weight-bold') { I18n.t("activerecord.attributes.dynamic/copy/mapping.#{direction}_klass") }
          if new_record? && mode != direction
            SELECT(class: 'form-control', value: record.send("#{direction}_klass_name") || '') do
              OPTION(value: '') { '— ' + I18n.t('shared.select') + ' —' }
              schema.klasses.sort_by { |k| label_for(k).downcase }.each do |k|
                OPTION(value: k.const_absolute_name) { label_for(k) }
              end
            end.on(:change) do |event|
              record.send("#{direction}_klass_name=", event.target.value)
              reset_klass_dependent_state
              mutate
            end
          else
            DIV(class: 'form-control-plaintext') { label_for(klass_by_name(record.send("#{direction}_klass_name"))) || '—' }
          end
        end
      end

      def reset_klass_dependent_state
        @target_attrs_initialized = false
        @has_many_rules_initialized = false
        @selected_pairs = {}
        @selected_has_many_rules = {}
        @fixed_record_labels = {}
      end

      def grid
        return unless source_klass_record && target_klass_record
        TABLE(class: 'table table-bordered') do
          THEAD do
            TR do
              TH { label_for(target_klass_record) }
              TH { I18n.t('crm.copy.mapping.source_col', klass: label_for(source_klass_record)) }
              TH { I18n.t('crm.copy.mapping.value_col') }
            end
          end
          TBODY do
            target_rows.each do |tgt|
              TR do
                TD { label_for(tgt) }
                if has_many?(tgt)
                  TD { has_many_source_select(tgt) }
                  TD { has_many_detail_cell(tgt) }
                else
                  sel = pair_selection_for(tgt)
                  TD { source_select(tgt, sel) }
                  TD { pair_detail_cell(tgt, sel) }
                end
              end
            end
          end
        end
        P(class: 'text-muted small') { I18n.t('crm.copy.mapping.has_many_help') } if target_has_manys.any?
      end

      def source_select(tgt, sel)
        SELECT(class: 'form-control form-control-sm', value: source_select_value(sel)) do
          OPTION(value: '') { I18n.t('crm.copy.mapping.empty_target') }
          compatible_source_fields(tgt).each do |src|
            OPTION(value: src.name) { label_for(src) }
          end
          if fixed_allowed?(tgt) || formula_allowed?(tgt)
            OPTGROUP(label: I18n.t('crm.copy.mapping.dynamic_values')) do
              OPTION(value: FIXED_OPTION) { I18n.t('crm.copy.mapping.source_fixed') } if fixed_allowed?(tgt)
              OPTION(value: FORMULA_OPTION) { I18n.t('crm.copy.mapping.source_formula') } if formula_allowed?(tgt)
            end
          end
        end.on(:change) do |event|
          select_source_for(tgt, event.target.value)
          mutate
        end
      end

      def source_select_value(sel)
        return '' unless sel
        case sel[:source_kind]
        when 'fixed' then FIXED_OPTION
        when 'formula' then FORMULA_OPTION
        else sel[:source_name] || ''
        end
      end

      def select_source_for(tgt, value)
        previous = pair_selection_for(tgt)
        selected_pairs[tgt.name] =
          case value
          when '' then nil
          when FIXED_OPTION
            { source_kind: 'fixed', fixed_value: previous && previous[:fixed_value] }
          when FORMULA_OPTION
            { source_kind: 'formula', formula: previous && previous[:formula] }
          else
            { source_kind: 'field', source_name: value }
          end
      end

      def fixed_allowed?(tgt)
        return false if attachment?(tgt)
        return !polymorphic_belongs_to?(tgt) if belongs_to?(tgt)
        true
      end

      def formula_allowed?(tgt)
        !attachment?(tgt) && !belongs_to?(tgt)
      end

      def polymorphic?(field)
        field.target_klass_id.nil?
      end

      def polymorphic_belongs_to?(field)
        belongs_to?(field) && polymorphic?(field)
      end

      def pair_detail_cell(tgt, sel)
        return unless sel
        case sel[:source_kind]
        when 'fixed' then fixed_value_input(tgt, sel)
        when 'formula' then formula_input(tgt, sel)
        end
      end

      def fixed_value_input(tgt, sel)
        if belongs_to?(tgt)
          fixed_record_select(tgt, sel)
        elsif enum?(tgt)
          fixed_enum_select(tgt, sel)
        else
          INPUT(
            type: 'text',
            class: 'form-control form-control-sm',
            value: sel[:fixed_value] || '',
            placeholder: I18n.t('crm.copy.mapping.fixed_value_placeholder'),
          ).on(:change) do |event|
            update_pair_selection(tgt, fixed_value: event.target.value)
            mutate
          end
        end
      end

      def fixed_enum_select(tgt, sel)
        values = observe tgt.values.to_a
        SELECT(class: 'form-control form-control-sm', value: sel[:fixed_value] || '') do
          OPTION(value: '') { '— ' + I18n.t('shared.select') + ' —' }
          values.each do |v|
            OPTION(value: v.name) { v.human_name.presence || v.name }
          end
        end.on(:change) do |event|
          update_pair_selection(tgt, fixed_value: event.target.value)
          mutate
        end
      end

      def fixed_record_select(tgt, sel)
        tgt_klass = klass_by_id(tgt.target_klass_id)
        return unless tgt_klass&.const
        label = fixed_record_label(tgt, sel, tgt_klass.const)
        InputWithAutocomplete({
          key: "fixed-record-#{tgt.name}-#{label}",
          input_args: {
            class: 'form-control form-control-sm',
            defaultValue: label,
            placeholder: '— ' + I18n.t('shared.select') + ' —',
          },
          search_url: tgt_klass.const.collection_path,
          template_result: Form::Element::Association::Base.template_result_ruby(tgt_klass.const),
        }).on(:select) do |event, item|
          select_fixed_record(tgt, item)
        end.on(:key_enter) do |event, item|
          select_fixed_record(tgt, item)
        end
      end

      def select_fixed_record(tgt, item)
        return unless item && item[:id]
        fixed_record_labels[tgt.name] = item[:text]
        update_pair_selection(tgt, fixed_value: item[:id])
        mutate
      end

      def fixed_record_labels
        @fixed_record_labels ||= {}
      end

      def fixed_record_label(tgt, sel, klass_const)
        known = fixed_record_labels[tgt.name]
        return known if known
        id = sel[:fixed_value]
        return nil if id.blank?
        r = observe klass_const.find(id)
        return nil unless r&.loaded?
        fixed_record_labels[tgt.name] = record_label(r)
      end

      def record_label(r)
        r.try(r.class.try(:name_attribute) || 'name') || r.id
      end

      def formula_input(tgt, sel)
        if ENV['FORMULA_EDITOR_PATH'].present? && lsp_url
          FormulaEditor(
            name: "copy_formula_#{tgt.name}",
            lsp_url: lsp_url,
            value: sel[:formula] || '',
          ).on(:change) do |v|
            update_pair_selection(tgt, formula: v)
          end
        else
          TEXTAREA(
            class: 'form-control form-control-sm',
            value: sel[:formula] || '',
            placeholder: I18n.t('crm.copy.mapping.formula_placeholder'),
          ).on(:change) do |event|
            update_pair_selection(tgt, formula: event.target.value)
            mutate
          end
        end
      end

      def lsp_url
        return unless source_klass_record
        href = App.location.href
        domain = href.split('/')[2]
        ws_protocol = href.start_with?('https') ? 'wss' : 'ws'
        schema_name = schema.name || schema.id
        "#{ws_protocol}://#{domain}#{ENV['APP_PATH_PREFIX']}/api/lsp/d/#{schema_name.underscore}/#{source_klass_record.name.underscore}"
      end

      def update_pair_selection(tgt, changes)
        current = pair_selection_for(tgt)
        selected_pairs[tgt.name] = (current || {}).merge(changes)
      end

      def has_many_source_select(tgt_assoc)
        SELECT(class: 'form-control form-control-sm', value: selected_source_assoc_for(tgt_assoc) || '') do
          OPTION(value: '') { I18n.t('crm.copy.mapping.empty_target') }
          compatible_source_has_manys(tgt_assoc).each do |src|
            OPTION(value: src.name) { label_for(src) }
          end
        end.on(:change) do |event|
          select_source_assoc_for(tgt_assoc, event.target.value)
          mutate
        end
      end

      def has_many_detail_cell(tgt_assoc)
        src_assoc_name = selected_source_assoc_for(tgt_assoc)
        return if src_assoc_name.blank?
        if share_ids_target?(tgt_assoc)
          DIV(class: 'text-muted small') do
            I(class: 'fas fa-link mr-1') {}
            SPAN { I18n.t('crm.copy.mapping.has_many_share_ids') }
          end
          return
        end
        DIV(class: 'text-muted small mb-1') { default_outcome_label_for(tgt_assoc) }
        child_mapping_select_for(tgt_assoc, src_assoc_name)
      end

      def child_mapping_select_for(tgt_assoc, src_assoc_name)
        return unless child_mapping_allowed?(tgt_assoc)
        src_assoc = source_has_manys.detect { |a| a.name == src_assoc_name }
        child_klass_name = klass_by_id(tgt_assoc.target_klass_id)&.const_absolute_name
        src_child_klass = klass_by_id(src_assoc&.target_klass_id)
        mappings = available_child_mappings_for(src_child_klass&.const_absolute_name, child_klass_name)
        SELECT(class: 'form-control form-control-sm', value: selected_child_mapping_for(tgt_assoc) || '') do
          OPTION(value: '') { I18n.t('crm.copy.mapping.has_many_no_child_mapping') }
          mappings.each do |m|
            OPTION(value: m.id) { m.name }
          end
        end.on(:change) do |event|
          select_child_mapping_for(tgt_assoc, event.target.value)
          mutate
        end
      end

      def default_outcome_label_for(tgt_assoc)
        return I18n.t('crm.copy.mapping.has_many_duplicated') if duplicated_target?(tgt_assoc)
        I18n.t('crm.copy.mapping.has_many_not_reproduced')
      end

      def footer_buttons
        DIV(class: 'd-flex justify-content-end mt-3') do
          A(class: 'btn bg-light mr-2', href: back_location) { I18n.t('shared.cancel') }
          BUTTON(class: 'btn btn-primary', type: 'button') do
            I18n.t('shared.save')
          end.on(:click) { save }
        end
      end

      def fields_for(klass_record)
        return [] unless klass_record
        cached("fields-#{klass_record.id}") do
          sort_by_label(
            klass_record.attrs.to_a.reject { |a| skip_attr?(a) } +
              klass_record.associations.to_a.select { |a| belongs_to?(a) } +
              klass_record.attachments.to_a
          )
        end
      end

      def has_manys_for(klass_record)
        return [] unless klass_record
        cached("has-manys-#{klass_record.id}") do
          sort_by_label(klass_record.associations.to_a.select { |a| has_many?(a) })
        end
      end

      def sort_by_label(fields)
        fields.sort_by { |field| label_for(field).to_s.downcase }
      end

      def source_fields
        fields_for(source_klass_record)
      end

      def target_fields
        fields_for(target_klass_record)
      end

      def source_has_manys
        has_manys_for(source_klass_record).reject { |a| a.through_id }
      end

      def target_has_manys
        has_manys_for(target_klass_record).reject { |a| a.through_id }
      end

      def target_rows
        cached(:target_rows) { sort_by_label(target_fields + target_has_manys) }
      end

      def skip_attr?(attr)
        return true unless attr.name
        return true if attr.name == 'id'
        return true if attr.name.end_with?('_id', '_type')
        return true if %w[created_at updated_at deleted_at].include?(attr.name)
        false
      end

      def belongs_to?(field)
        ::Dynamic::Copy::TypeCompatibility.belongs_to?(field)
      end

      def has_many?(field)
        ::Dynamic::Copy::TypeCompatibility.has_many?(field)
      end

      def attachment?(field)
        ::Dynamic::Copy::TypeCompatibility.attachment?(field)
      end

      def enum?(field)
        field.type == 'Enum'
      end

      def compatible?(src, tgt)
        ::Dynamic::Copy::TypeCompatibility.compatible?(src, tgt)
      end

      def label_for(field)
        return nil unless field
        field.human_name || field.name
      end

      def compatible_source_fields(tgt)
        source_fields.select { |src| compatible?(src, tgt) }
      end

      def compatible_source_has_manys(tgt_assoc)
        taken = taken_source_assoc_names_except(tgt_assoc)
        source_has_manys.select do |src|
          compatible_has_many?(src, tgt_assoc) && !taken.include?(src.name)
        end
      end

      def compatible_has_many?(src, tgt_assoc)
        polymorphic?(tgt_assoc) || src.target_klass_id == tgt_assoc.target_klass_id
      end

      def taken_source_assoc_names_except(tgt_assoc)
        result = []
        target_has_manys.each do |other|
          next if other.name == tgt_assoc.name
          name = selected_source_assoc_for(other)
          result << name if name.present?
        end
        result
      end

      def duplicated_target?(tgt_assoc)
        tgt_assoc&.dependent_destroy ? true : false
      end

      def child_mapping_allowed?(tgt_assoc)
        return false unless tgt_assoc
        !share_ids_target?(tgt_assoc) && !polymorphic?(tgt_assoc)
      end

      def share_ids_target?(tgt_assoc)
        return false unless tgt_assoc
        return false if duplicated_target?(tgt_assoc)
        !belongs_to_inverse?(tgt_assoc)
      end

      def belongs_to_inverse?(tgt_assoc)
        return false unless tgt_assoc&.inverse_of_id
        inverse = schema.associations_by_id[tgt_assoc.inverse_of_id]
        inverse ? belongs_to?(inverse) : false
      end

      def available_child_mappings_for(source_klass_name, target_klass_name)
        return [] unless source_klass_name && target_klass_name
        cached("child-mappings-#{source_klass_name}-#{target_klass_name}") do
          collection = observe mapping_class.where(source_klass_name: source_klass_name, target_klass_name: target_klass_name).all
          collection.to_a.reject { |m| m.id && record && m.id == record.id }
        end
      end

      def selected_pairs
        @selected_pairs ||= {}
      end

      def pairs_by_target_name
        cached(:pairs_by_target_name) do
          record.pairs.to_a.each_with_object({}) { |p, h| h[p.target_name] = p }
        end
      end

      def pair_selection_for(tgt)
        return selected_pairs[tgt.name] if selected_pairs.key?(tgt.name)
        existing = pairs_by_target_name[tgt.name]
        return nil unless existing
        {
          source_kind: existing.source_kind || 'field',
          source_name: existing.source_name,
          fixed_value: existing.fixed_value,
          formula: existing.formula,
        }
      end

      def pair_selection_complete?(sel)
        return false unless sel
        case sel[:source_kind]
        when 'fixed' then sel[:fixed_value].present?
        when 'formula' then sel[:formula].present?
        else sel[:source_name].present?
        end
      end

      def selected_has_many_rules
        @selected_has_many_rules ||= {}
      end

      def rules_by_target_name
        cached(:rules_by_target_name) do
          record.has_many_rules.to_a.each_with_object({}) { |r, h| h[r.target_name] = r }
        end
      end

      def existing_has_many_rule_for(tgt_assoc_name)
        rules_by_target_name[tgt_assoc_name]
      end

      def selected_source_assoc_for(tgt_assoc)
        has_many_rule_selection_for(tgt_assoc)[:source_name]
      end

      def select_source_assoc_for(tgt_assoc, source_assoc_name)
        name = source_assoc_name.presence
        changes = { source_name: name }
        changes[:child_mapping_id] = nil if name.nil?
        update_has_many_rule_selection(tgt_assoc, changes)
      end

      def selected_child_mapping_for(tgt_assoc)
        has_many_rule_selection_for(tgt_assoc)[:child_mapping_id]
      end

      def select_child_mapping_for(tgt_assoc, child_mapping_id)
        update_has_many_rule_selection(tgt_assoc, child_mapping_id: child_mapping_id.presence)
      end

      def has_many_rule_selection_for(tgt_assoc)
        selected_has_many_rules[tgt_assoc.name] || persisted_has_many_rule_selection_for(tgt_assoc)
      end

      def persisted_has_many_rule_selection_for(tgt_assoc)
        existing = existing_has_many_rule_for(tgt_assoc.name)
        {
          source_name: existing&.source_name,
          child_mapping_id: existing&.child_mapping_id,
        }
      end

      def update_has_many_rule_selection(tgt_assoc, changes)
        current = has_many_rule_selection_for(tgt_assoc)
        selected_has_many_rules[tgt_assoc.name] = current.merge(changes)
      end

      def initialize_target_attrs_once
        return if @target_attrs_initialized
        return unless source_klass_record && target_klass_record
        return unless new_record?
        return if record.pairs.to_a.any?
        @target_attrs_initialized = true
        target_fields.each do |tgt|
          tgt_name = label_for(tgt).to_s.downcase
          match = source_fields.detect do |src|
            label_for(src).to_s.downcase == tgt_name && compatible?(src, tgt)
          end
          selected_pairs[tgt.name] = { source_kind: 'field', source_name: match.name } if match
        end
        if record.name.blank?
          record.name = "#{label_for(source_klass_record)} → #{label_for(target_klass_record)}"
        end
      end

      def initialize_has_many_rules_once
        return if @has_many_rules_initialized
        return unless source_klass_record && target_klass_record
        return unless new_record?
        return if record.has_many_rules.to_a.any?
        @has_many_rules_initialized = true
        taken = []
        target_has_manys.each do |tgt|
          tgt_name = label_for(tgt).to_s.downcase
          match = source_has_manys.detect do |src|
            label_for(src).to_s.downcase == tgt_name &&
              compatible_has_many?(src, tgt) &&
              !taken.include?(src.name)
          end
          if match
            selected_has_many_rules[tgt.name] = { source_name: match.name, child_mapping_id: nil }
            taken << match.name
          end
        end
      end

      def existing_field_names(klass_record)
        return [] unless klass_record
        cached("field-names-#{klass_record.id}") do
          (klass_record.attrs.to_a + klass_record.associations.to_a + klass_record.attachments.to_a).map(&:name)
        end
      end

      def append_orphan_destroys(attrs, existing_by_key, known_keys)
        return if known_keys.empty?
        existing_by_key.each do |key, existing|
          attrs << { id: existing.id, _destroy: '1' } unless known_keys.include?(key)
        end
      end

      def append_stale_rule_destroys(rules_attrs)
        known_targets = existing_field_names(target_klass_record)
        known_sources = existing_field_names(source_klass_record)
        return if known_targets.empty? || known_sources.empty?
        rules_by_target_name.each do |target_name, existing|
          next if known_targets.include?(target_name) && known_sources.include?(existing.source_name)
          next if rules_attrs.any? { |attrs| attrs[:id] == existing.id }
          rules_attrs << { id: existing.id, _destroy: '1' }
        end
      end

      def save
        pairs_attrs = []
        target_fields.each do |tgt|
          sel = pair_selection_for(tgt)
          existing = pairs_by_target_name[tgt.name]
          unless pair_selection_complete?(sel)
            pairs_attrs << { id: existing.id, _destroy: '1' } if existing
            next
          end
          kind = sel[:source_kind] || 'field'
          pair_attrs = {
            target_name: tgt.name,
            source_kind: kind,
            source_name: kind == 'field' ? sel[:source_name] : nil,
            fixed_value: kind == 'fixed' ? sel[:fixed_value] : nil,
            formula: kind == 'formula' ? sel[:formula] : nil,
          }
          pair_attrs[:id] = existing.id if existing
          pairs_attrs << pair_attrs
        end
        append_orphan_destroys(pairs_attrs, pairs_by_target_name, existing_field_names(target_klass_record))

        rules_attrs = []
        selected_has_many_rules.each do |tgt_assoc_name, data|
          src_assoc_name = data[:source_name]
          existing = rules_by_target_name[tgt_assoc_name]
          if src_assoc_name.blank?
            rules_attrs << { id: existing.id, _destroy: '1' } if existing
            next
          end
          tgt_assoc = target_has_manys.detect { |a| a.name == tgt_assoc_name }
          rule_attrs = {
            source_name: src_assoc_name,
            target_name: tgt_assoc_name,
            child_mapping_id: child_mapping_allowed?(tgt_assoc) ? data[:child_mapping_id] : nil,
          }
          rule_attrs[:id] = existing.id if existing
          rules_attrs << rule_attrs
        end
        append_stale_rule_destroys(rules_attrs)

        attrs = {
          name: record.name,
          source_klass_name: record.source_klass_name.presence || initial_source_klass_name,
          target_klass_name: record.target_klass_name.presence || initial_target_klass_name,
          pairs_attributes: pairs_attrs,
          has_many_rules_attributes: rules_attrs,
        }
        record.update(attrs).then do |response|
          if response[:success]
            App.history.push(back_location) if back_location
          else
            mutate
          end
        end
      end

    end
  end
end
