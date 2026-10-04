class Api::Dynamic::Schema::Import::BaseController < Api::Dynamic::Schema::BaseController

  def controller_class_name_to_klass_name
    "#{super.gsub('::Schema::', '::')}::Base"
  end

end