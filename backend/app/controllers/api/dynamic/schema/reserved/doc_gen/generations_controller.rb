# frozen_string_literal: true

class Api::Dynamic::Schema::Reserved::DocGen::GenerationsController < Api::Dynamic::Schema::Reserved::BaseController

  skip_verify_authenticity_token_for_jwt

  before_action :find_template!
  before_action :find_records!

  def create
    @generation = ::Dynamic::DocGen::Generation.new(element_params.deep_merge({
      output_name: params.dig(:generation, :output_name),
      options: generation_options,
      records: @records,
      template: @template,
      prevent_progress_success: true,
    }))
    @generation.valid?
    if @generation.errors.empty?
      generation_worker_options = {}
      if @generation.options[:notification] != ''
        notification_attributes = {}
        I18n.available_locales.each do |l|
          I18n.with_locale(l) do
            notification_attributes["title_#{l}"] = I18n.t('notification.titles.doc_gen', template: @template.name, klass: schema_klass.human_name)
          end
        end
        generation_worker_options['notification_attributes'] = notification_attributes
      end
      ::Dynamic::DocGen::Worker.perform_async(*::Dynamic::DocGen::Worker.serialize_args(*@generation.args_to_serialize_for_worker), generation_worker_options)
    else
      raise ActiveRecord::RecordInvalid.new(@generation)
    end

    render json: @generation.as_json, status: :created
  end

  private

  def demodulized_klass_name
    'DocGen::Template'
  end

  def find_template!
    @template ||= klass.where(class_name: schema_klass.const_absolute_name).find(params[:template_id])
  end

  def find_records!
    return @records if @records
    if params.dig(:generation, :record_ids)
      @records = schema_klass.const.find(params.dig(:generation, :record_ids))
    else
      @records = schema_klass.const.find(params.dig(:generation, :record_id))
    end
  end

  def notification_klass
    @notification_klass ||= "#{@schema.const.name}::R::Notification".safe_constantize
  end

  def element_params
    @element_params ||= params.require(:generation).permit(:super_merge, :merge, :files, :attachment).to_h
  end

  def generation_options
    result = params.dig(:generation, :options)&.permit!&.to_unsafe_hash
    result ||= {}.with_indifferent_access
    result[:output_mode] = :save
    return result
  end

end
