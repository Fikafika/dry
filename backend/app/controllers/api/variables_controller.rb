class Api::VariablesController < ::Api::BaseController
  include LoadSchema

  VARIABLE_PATTERN = /[@\w\d]+[\.\w+@\d+]*/

  prepend_around_action :load_schema
  prepend_before_action :validate_context_params

  class FormulaProcessingError < StandardError
    def api_status_error
      :unprocessable_content
    end
  end

  class RecordNotFoundError < FormulaProcessingError
    def api_status_error
      :not_found
    end
  end

  class NamespaceError < FormulaProcessingError; end

  def index
    context = params[:context]
    formula = params[:formula]

    attachment_key = params[:attachment_key]
    attachment_key = "blob.filename" unless attachment_key.present?

    begin
      result = process_formula(formula, context, attachment_key)

      render :json => {'result' => result, 'errors' => @errors}, :status => :ok
    rescue FormulaProcessingError => e
      render :json => {'result' => e.message}, :status => e.api_status_error
    end
  end

  def schema_name
    @schema_name ||= schema_param.classify_permalink
  end

  def klass
    nil
  end

  private

  def validate_context_params
    params.require(:context).each do |key, value|
      raise RecordNotFoundError.new("Missing record ID for context '#{key}'") unless value[:id].present?
      raise ActionController::ParameterMissing.new(:klass) unless value[:klass].present?
    end
    params.require(:formula)
    params.permit!
  end

  def process_formula(formulas, context, attachment_key = nil)
    @errors = {}
    if formulas.is_a?(Array)
      return {} if formulas.empty?

      is_multiple = true
      formula_list = formulas
    else
      return "" unless formulas.present?

      is_multiple = false
      formula_list = [formulas]
    end

    variables = formulas_variables(formula_list)

    variables_values = find_variables_values(variables, context, attachment_key)

    new_formula_list, variables_values_by_formula_key = rename_formula_variables(formula_list, variables_values)

    results = evaluate_formulas(new_formula_list, variables_values_by_formula_key)

    unless is_multiple
      results = results[formulas]
      results = "" unless results.present?
    end

    results
  end

  def formulas_variables(formulas)
    formulas.each_with_object(Set.new) do |f, vars|
      next unless f.present?
      v = f.scan(VARIABLE_PATTERN)
      vars.merge(v) unless v.nil?
    end
  end

  def find_variables_values(variables, context, attachment_key)
    variables_values = {}

    records_json = find_record_json_by_context(variables, context)

    variables.each do |v|

      splitted_variable = v.split('.')
      context_name = splitted_variable.shift

      next unless context.include?(context_name)

      current_context = context[context_name]

      value = records_json.dig(current_context['klass'], current_context['id'])

      splitted_variable.each do |method|
        m, index = method.split('@')
        index = index.to_i if index.present?
        if m.blank? && index.blank?
          value = nil
          break
        elsif value.is_a?(Array)
          value = value.map { |val| index.present? ? val.dig(m, index) : val[m] }
        elsif value.is_a?(Hash)
          value = index.present? ? value.dig(m, index) : value[m]
        else
          value = nil
          break
        end
      end

      variables_values[v] = convert_non_single_value(value, attachment_key)
    end

    variables_values
  end

  def find_record_json_by_context(variables, context)
    records_json = {}

    records_variables_by_context(variables, context).each do |klass, records|
      records_json[klass] = {}
      records.each do |id, data|
        r = data[:record]
        records_json[klass][id] = r.as_json(r.class.includes_for_variables(data[:variables]))
      end
    end

    records_json
  end

  def records_variables_by_context(variables, context)
    records_variables = {}

    variables.each do |variable|
      vars = variable.split('.')
      context_name = vars.shift
      next unless context.include?(context_name)

      id = context[context_name]['id']
      klass = context[context_name]['klass']

      records_variables[klass] = {} unless records_variables.include?(klass)

      begin
        records_variables[klass][id] = {
          :record => find_record(id, klass),
          :variables => Set.new
        } unless records_variables[klass].include?(id)
      rescue ActiveRecord::RecordNotFound
        raise RecordNotFoundError.new("Record for '#{context_name}' not found")
      rescue NameError => e
        if "D::#{schema_name}".safe_constantize
          raise NamespaceError.new("Klass '#{klass}' is not defined")
        else
          raise NamespaceError.new("Schema '#{schema_param}' not defined")
        end
      rescue => e
        raise FormulaProcessingError.new("Error getting value for variable #{variable}: #{e.class.to_s} #{e.message}")
      end

      records_variables[klass][id][:variables] << vars.join('.')
    end

    records_variables
  end

  def find_record(id, klass)

    @records ||= {}

    return @records[id] if @records.include?(id)

    @records[id] = "D::#{schema_name}::#{klass}".constantize.find(id)
  end

  def convert_non_single_value(value, default_key)
    if value.is_a?(Hash)
      default_value = nil
      if default_key.present?
        # try to get default_key when value is a hash
        default_value = value.dig(*default_key.split('.'))
      end

      attributes_values = value.select { |k, v| !v.is_a?(Hash) && !v.is_a?(Array) }

      if default_value.nil? && attributes_values.length == 1
        # access name_attribute value when value is a Hash representing a record
        value = value.values.first
      else
        value = default_value
      end
    elsif value.is_a?(Array)
      value = value.map { |v| convert_non_single_value(v, default_key) }
    end

    value
  end

  def rename_formula_variables(formula_list, variables_values)
    variables_values_by_formula_key = {}
    formula_keys_by_variable = {}
    variables_values.each do |v, value|
      formula_variable_key = rename_variable(v)

      variables_values_by_formula_key[formula_variable_key] = value
    end

    new_formula_list = {}
    formula_list.each do |formula|
      new_formula_list[formula] = formula.gsub(VARIABLE_PATTERN) { |v| rename_variable(v) }
    end

    [new_formula_list, variables_values_by_formula_key]
  end

  def rename_variable(variable)
    variable.gsub('.', '__DOT__').gsub('@', '__AT__')
  end

  def evaluate_formulas(formula_list, variables_values)
    results = {}

    formula_list.each do |formula, new_formula|
      begin
        results[formula] = new_formula.present? ? Uneek::Formula.new(new_formula).eval(variables: variables_values) : ''
      rescue => e
        Rails.logger.error "Error evaluating formula \"#{formula}\": #{e.message}"
        results[formula] = nil
        @errors[formula] = e.message
      end
    end

    results
  end

  def schema_param
    @schema_param ||= params.require(:schema_name)
  end

  concerning :Cache do

    def manifest_scope
      manifest_scope_for_schema_name(schema_name)
    end

  end

  concerning :Authorization do

    def skip_permissions?
      current_user_is_admin?
    end

    def check_permissions
      raise UneekPermission::UnauthorizedAction unless action_name == 'index'

      instances_by_klass = {}
      params.require(:context).each_value do |value|
        klass_name = "D::#{schema_name}::#{value[:klass]}"
        instance = find_record(value[:id], value[:klass])
        next unless instance
        instances_by_klass[klass_name] ||= []
        instances_by_klass[klass_name] << instance
      end

      permission_retriever = UneekPermission::Retriever::Permission.new(
        user: User.current,
        instance: instances_by_klass.first[1],
        attributes: instances_by_klass.first[0].safe_constantize.dynamic_attribute_types.keys
      )

      instances_by_klass.each do |klass_name, instances|
        permission_retriever.instance = instances
        result = permission_retriever.retrieve(as: :hash)
        params[:context].each do |key, value|
          klass_permission_for_instance = result.dig(klass_name, value[:id], :self)
          next if klass_permission_for_instance.include?('R')
          params[:context].delete(key)
        end
      end
    end

  end

end
