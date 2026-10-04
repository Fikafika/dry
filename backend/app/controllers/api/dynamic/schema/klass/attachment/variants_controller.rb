class Api::Dynamic::Schema::Klass::Attachment::VariantsController < Api::Dynamic::Schema::Klass::Attachment::BaseController

  private

  def klass
    Dynamic::Schema::Attachment::Variant
  end

  def scope
    @scope ||= schema_attachment.variants
  end

end
