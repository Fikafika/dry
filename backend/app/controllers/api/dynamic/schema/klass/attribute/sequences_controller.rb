class Api::Dynamic::Schema::Klass::Attribute::SequencesController < Api::Dynamic::Schema::Klass::Attribute::BaseController

  private

  def scope
    @scope ||= schema_attr.sequences
  end

  def controller_class_name_to_klass_name
    'Dynamic::Schema::Sequence'
  end
end
