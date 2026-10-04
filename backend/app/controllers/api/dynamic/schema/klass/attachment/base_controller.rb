class Api::Dynamic::Schema::Klass::Attachment::BaseController < Api::Dynamic::Schema::Klass::BaseController

  private

  def schema_attachment
    @schema_attachment ||= find_by_id_or_name(schema_klass.attachments, params[:attachment_id], :underscore)
    @schema_attachment
  end

  def where_exceptions
    super + ['attachment_id']
  end

end
