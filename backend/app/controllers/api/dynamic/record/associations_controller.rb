class Api::Dynamic::Record::AssociationsController < Api::Dynamic::Record::BaseController

  before_action :check_association_owner_presence

  def destroy
    owner = @element.association_owner
    assoc = owner.class.reflect_on_association(@element.schema_association.name)
    case assoc.macro
    when :has_one
      @element.association_owner.update!("#{assoc.name}_id": nil)
    when :has_many
      @element.association_owner.update!("#{assoc.name}_attributes": [{id: @element.association_target_id, type: @element.association_target_type, _destroy: true}])
    end
    head :no_content
  end

  private

  def klass
    @klass ||= "D::#{params[:schema_name].classify_permalink}::DynamicAssociation".constantize
  end

  def element_params_key
    'dynamic_association'
  end

  def schema
    params_schema_id = params[:schema_id] || params[:schema_name]
    @schema ||= find_by_id_or_name(Dynamic::Schema, params_schema_id, :classify_permalink)
  end

  def to_json(a)
    result = a.respond_to?(:as_deep_json) ? a.as_deep_json(deep_json_options(a)) : a

    if params[:pretty_print]
      result = JSON.pretty_generate(result)
    else
      result = result.to_json
    end

    return result
  end

  def deep_json_options(a)
    r = params.to_unsafe_hash.slice('only', 'include')
    r.merge!({ :secure => false })  # TODO don't keep that !!

    if r.dig('include', 'association_target') == '1'
      r['include']['association_target'] = includes_for_association_target(a)
    end

    return r
  end

  def includes_for_association_target(a)
    target_klass_names = Set.new
    schema_association_ids = Set.new
    a.each do |da|
      target_klass_names.add(da.association_target_type)
      schema_association_ids.add(da.schema_association_id)
    end

    excepts = {}
    Dynamic::Schema::Association::Base.where(id: schema_association_ids, schema_id: schema.id).includes(target_klass: {}, inverse_of: {}).each do |sa| # TODO implement schema.association_by_id
      target_klass_name = sa.target_klass&.const_absolute_name
      inverse = sa.inverse_of&.name
      next unless target_klass_name && inverse
      (excepts[target_klass_name] ||= []) << inverse
    end

    per_type = {}
    target_klass_names.each do |target_klass_name|
      form = schema.forms.with_actions([:show]).where(klass_name: target_klass_name, default: true, mode: :read_only).first
      next unless form
      includes = form.includes_for_load_record
      if except = excepts[target_klass_name]
        except.each do |e|
          includes[:include].delete(e)
          includes[:include].delete(e.to_sym)
        end
      end
      per_type[target_klass_name] = includes
    end

    result = {
      per_type: per_type
    }

    return result
  end

  def check_association_owner_presence
    if association_owner_klass.nil? || params.dig(:where, :association_owner_id).nil?
      render json: { message: 'Cannot find associations without association_owner' }, status: :unprocessable_content
    end
  end

  def association_owner_klass
    params.dig(:where, :association_owner_type)&.safe_constantize
  end

  def association_owner
    association_owner_klass.find(params.dig(:where, :association_owner_id))
  end

  def allowed_scopes
    super + ['for_schema_associations']
  end

  concerning :Authorization do

    def check_permissions
      if action_name.in?(['index', 'show']) && association_owner_klass.include?(::UneekPermission::ControlledKlass)
        raise UneekPermission::UnauthorizedAction, "You are not allowed to read this object's associations" unless association_owner.can_be_read_by?(current_user)
      else
        super
      end
    end

  end

  concerning :Cache do

    def manifest_scope
      params_schema_id = params[:schema_id] || params[:schema_name]
      if id?(params_schema_id)
        manifest_scope_for_schema_id(params_schema_id)
      else
        manifest_scope_for_schema_name(params_schema_id.classify_permalink)
      end
    end

  end

end
