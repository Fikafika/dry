class Api::Dynamic::Schema::CascadesController < Api::Dynamic::Schema::BaseController

  before_action :nullify_blank_values

  def nullify_blank_values
    owner_id = params.dig(:where, :owner_id)
    return unless owner_id.is_a?(Array)
    owner_id.each_with_index do |v, i|
      owner_id[i] = nil if v.blank?
    end
  end

  def klass
    Dynamic::Cascade
  end

end
