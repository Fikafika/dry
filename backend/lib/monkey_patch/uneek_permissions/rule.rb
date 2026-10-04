ActiveSupport.on_load(:uneek_permission_rule) do

  concerning :Forms do

    included do
      after_create :create_default_form_rule_from_dynamic_klass, if: :rule_apply_on_forms_klass?
      after_update :update_default_form_rule_from_dynamic_klass, if: :rule_apply_on_forms_klass?
      after_destroy :destroy_default_form_rule_from_dynamic_klass, if: :rule_apply_on_forms_klass?
    end

    def rule_apply_on_forms_klass?
      self.receiver_type != 'UneekPermission::PredefinedReceiver::Public' && klass_inherit_dynamic_record?
    end

    private

    def create_default_form_rule_from_dynamic_klass
      return if grant == UneekPermission::Rule::ACTION_TO_FLAG[:D] || grant == UneekPermission::Rule::EMPTY_PERMISSION

      has_grant_for_update = self.has_permission?(:U)

      create_rules_for_dynamic_forms(self.grant, with_associated_forms: has_grant_for_update) do |forms|
        filter_forms_by_existing_rules_with_mode_and_association_name(forms)
      end
    end

    def update_default_form_rule_from_dynamic_klass
      return unless self.previous_changes[:grant]
      previous_grant = self.previous_changes[:grant].first
      current_grant = self.previous_changes[:grant].second
      grant_to_add = ~previous_grant & current_grant
      grant_to_remove = previous_grant & ~current_grant

      if self.class.has_permission?(:R, grant_to_add)
        grant_to_remove &= ~UneekPermission::Rule::ACTION_TO_FLAG[:U]
        grant_to_remove &= ~UneekPermission::Rule::ACTION_TO_FLAG[:R]
      end

      has_grant_for_update_to_add = self.class.has_permission?(:U, grant_to_add)
      create_rules_for_dynamic_forms(grant_to_add, with_associated_forms: has_grant_for_update_to_add) do |forms|
        filter_forms_by_existing_rules_with_mode_and_association_name(forms)
      end

      grant_to_keep = grant_from_permissions
      grant_to_remove &= ~grant_to_keep

      modes_to_remove = dynamic_form_modes_from_grant(grant_to_remove)
      has_grant_for_update_to_keep = self.class.has_permission?(:U, grant_to_add) || self.class.has_permission?(:U, grant_to_keep)
      modes_to_remove.delete('edit_in_place') if has_grant_for_update_to_keep

      destroy_rules_for_dynamic_forms(modes_to_remove, with_associated_forms: has_grant_for_update_to_keep)
    end

    def destroy_default_form_rule_from_dynamic_klass
      return if grant == UneekPermission::Rule::ACTION_TO_FLAG[:D] || grant == UneekPermission::Rule::EMPTY_PERMISSION

      grant_to_remove = self.grant
      grant_to_keep = grant_from_permissions
      grant_to_remove &= ~grant_to_keep

      modes_to_remove = dynamic_form_modes_from_grant(self.grant)
      has_grant_for_update_to_keep = self.class.has_permission?(:U, grant_to_keep)
      modes_to_remove.delete('edit_in_place') if has_grant_for_update_to_keep

      destroy_rules_for_dynamic_forms(modes_to_remove, with_associated_forms: has_grant_for_update_to_keep)
    end

    def create_rules_for_dynamic_forms(grant, with_associated_forms: false)
      modes = dynamic_form_modes_from_grant(grant)
      scope = Dynamic::Form.where(
        klass_name: self.klass_name,
        default: true,
        mode: modes
      )
      has_grant_for_update = self.class.has_permission?(:U, grant)
      scope = scope.or(scope_for_associated_klass_forms) if has_grant_for_update
      scope = yield(scope) if block_given?
      create_dynamic_form_rules_from_scope(scope)
    end

    def create_dynamic_form_rules_from_scope(form_scope)
      form_scope.find_each do |f|
        UneekPermission::Rule.create_with(
          schema: self.schema,
          grant: UneekPermission::Rule::ACTION_TO_FLAG[:R]
        ).find_or_create_by(
          klass_name: 'Dynamic::Form',
          receiver: self.receiver,
          instance: f
        )
      end
    end

    def destroy_rules_for_dynamic_forms(modes, with_associated_forms: false)
      scope = Dynamic::Form.where(
        klass_name: self.klass_name,
        default: true,
        mode: modes
      )
      scope = scope.or(scope_for_associated_klass_forms) unless with_associated_forms
      destroy_dynamic_form_rules_from_scope(scope)
    end

    def destroy_dynamic_form_rules_from_scope(form_scope)
      form_scope.select(:id).find_in_batches do |batch|
        UneekPermission::Rule.where(
          klass_name: 'Dynamic::Form',
          receiver: self.receiver,
          grant: UneekPermission::Rule::ACTION_TO_FLAG[:R],
          instance: batch
        ).destroy_all
      end
    end

    def dynamic_form_modes_from_grant(grant)
      modes = []
      modes << 'input' if self.class.has_permission?(:C, grant)
      modes << 'read_only' if self.class.has_permission?(:R, grant)
      # edit_in_place is also used as visiualisation
      modes << 'edit_in_place' if self.class.has_permission?(:U, grant) || self.class.has_permission?(:R, grant)
      return modes
    end

    def scope_for_associated_klass_forms
      where_attrs = {
        association_klass_name: self.klass_name,
        target_klass_name: self.klass_name,
        default: true,
        mode: 'input'
      }
      if self.attr
        assoc = self.klass.reflect_on_association(self.attr)
        where_attrs[:klass_name] = assoc.klass.name if assoc
      end
      return Dynamic::Form.where(where_attrs)
    end

    def filter_forms_by_existing_rules_with_mode_and_association_name(scope)
      dynamic_form_table = Dynamic::Form.arel_table
      permission_table = UneekPermission::Rule.arel_table
      join_sources = dynamic_form_table.join(permission_table).on(dynamic_form_table[:id].eq(permission_table[:instance_id])).join_sources
      existing_form_with_rules = Dynamic::Form.joins(join_sources).where(default: true, klass_name: self.klass_name).merge(
        UneekPermission::Rule.with_right(:R).for_receiver(self.receiver, with_public: false)
      ).all
      blacklist = existing_form_with_rules.map do |f|
        Arel::Nodes::Grouping.new([
          Dynamic::Form.modes[f.mode],
          Arel::Nodes.build_quoted(f.association_name.to_s)
        ])
      end
      return scope.where(
        Arel::Nodes::Grouping.new([
          dynamic_form_table[:mode],
          Arel::Nodes::NamedFunction.new('COALESCE', [dynamic_form_table[:association_name], Arel::Nodes.build_quoted('')])
        ]).in(blacklist).not
      )
    end

    private

    def grant_from_permissions
      return UneekPermission::Rule::EMPTY_PERMISSION unless self.receiver
      permissions = self.klass.uneek_permissions_for_user(self.receiver)
      permissions.values.flatten.inject(0) {|i, g| i |= g.grant}
    end

  end

  concerning :Cache do

    included do
      after_save :invalid_reserved_klass_cache, if: :is_klass_name_reserved_for_schema?
    end

    def is_klass_name_reserved_for_schema?
      klass_name =~ /^D::(\w)*::R::/
    end

    def invalid_reserved_klass_cache
      splitted_class_name = klass_name.split('::')
      schema_path = splitted_class_name[1].underscore
      klass_path = splitted_class_name[3..-1].map(&:underscore)
      klass_path[-1] = klass_path[-1].pluralize
      Rails.cache.delete_matched("d/#{schema_path}/r/#{klass_path.join('/')}/*")
    end
  end

  concerning :ManifestAssignement do

    included do
      before_validation :assign_manifest_from_schema
    end

    def assign_manifest_from_schema
      return if manifest_id
      self.manifest_id = UneekPermission::Manifest.joins(:community).where(community: {schema_id: self.schema&.id}).pluck(:id).first
    end
  end

end