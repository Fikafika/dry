# backtick_javascript: true

require 'components/klass_from_method_name'

class RecordVersions < HyperComponent

  param :record_type
  param :record_id

  collect_other_params_as :other_params

  render do
    versions.each do |v|
      Item(record_klass: record_klass, record_id: record_id, version: v)
    end
  end

  def record_klass
    record_type.constantize
  end

  def versions
    observe @versions ||= version_klass.where(item_id: record_id, timestamp: Time.now.to_i).order(id: :desc).limit(10000).all
  end

  def version_klass
    "#{record_type}Version".constantize
  end

  class Item < HyperComponent
    include KlassFromMethodName

    param :record_klass
    param :record_id
    param :version

    render do
      DIV(class: 'p-2 border-bottom') do
        header
        version.changeset&.each do |field_name, change|
          DIV(class: '') do
            label(field_name)
            Diff.create_element(
              klass: record_klass,
              field_name: field_name,
              change: change,
              data_for_change: version.data_for_changeset,
            ).render
          end
        end
      end
    end

    def label(field_name)
      SPAN(class: '') do
        record_klass.human_attribute_name(remove_id_from_field_name(field_name))
      end
    end

    def remove_id_from_field_name(field_name)
      record_klass.reflect_on_association_from_method_name(field_name)&.name || field_name
    end

    def header
      DIV(class: 'd-flex flex-row mb-2') do
        DIV(class: '') do
          version.human_attribute_value(:event, version.event)
        end
        DIV(class: 'd-flex flex-grow-1') do
        end
        DIV(class: 'small text-muted') do
          source
          author_and_created_at
        end
      end
    end

    def source
      if version.source
        if version.source.try(:url)
          A(href: source_url, class: 'text-muted', target: '_blank') do
            source_name
          end
        else
          SPAN do
            source_name
          end
        end
        SPAN do
          " - "
        end
      end
    end

    def source_url
      sep = version.source.url.include?('?') ? '&' : '?'
      return "#{version.source.url}#{sep}record_id=#{record_id}&record_type=#{record_klass.name}"
    end

    def source_name
      [
        version.source.class.model_name.human,
        version.source.try(:human_name) || version.source.try(:name)
      ].compact.join(' - ')
    end

    def author_and_created_at
      SPAN do
        [
          (version.author.name_or_login if version.author),
          I18n.l(version.created_at),
        ].compact.join(' - ')
      end
    end

    module Diff
      include KlassFromMethodName

      def self.create_element(params = {})
        element_klass = klass_from_method_name(params[:klass], params[:field_name], raise_if_missing: false ) || Deleted
        element_klass.create_element(params)
      end

      class Base < HyperComponent
        param :change
        param :klass
        param :field_name
        param :data_for_change

        collect_other_params_as :other_params

        def previous
          change[0]
        end

        def current
          change[1]
        end

        render do
          if !previous.nil?
            value_layout('danger') do
              render_value(previous)
            end
          end
          if !current.nil?
            value_layout('success') do
              render_value(current)
            end
          end
        end

        def value_layout(color)
          css_class = "bg-#{color}-subtle p-1 mx-2 d-inline-block"
          if color == 'danger'
            DEL(class: css_class) { yield }
          else
            SPAN(class: css_class) { yield }
          end
        end

        def render_value(value)
          value.to_s
        end
      end

      class Deleted < Diff::Base
        render do
          SPAN(class: 'bg-danger-subtle p-1 mx-2') do
            I18n.t('record_versions.deleted_field')
          end
        end
      end

      module Attribute
        class Base < Diff::Base
        end

        class Boolean < Base

          def render_value(value)
            case value
            when true, '1'
              I18n.t('shared._yes')
            when false, '0'
              I18n.t('shared._no')
            end
          end

        end

        class DateTime < Base

          def render_value(value)
            return nil unless value
            m = `moment(#{value})`
            if `#{m}.isValid()`
              result = `#{m}.format(#{display_format})`
              result = nil if result == 'Invalid date'
            end
            return result
          end

          def display_format
            I18n.t('format.date_time')
          end

        end

        class Date < DateTime

          def display_format
            I18n.t('format.date')
          end

        end

        class Enum < Base
          def render_value(value)
            klass.human_attribute_value(field_name, value)
          end
        end

        class Text < Base
          def render_value(value)
            DIV(dangerously_set_inner_HTML: { __html: value}) do
            end
          end
        end

        class TranslatableText < Text
        end
      end


      module Association
        class Base < Diff::Base
          include Hyperstack::Router::Helpers
          include UrlHelper

          def render_value(value)
            if data_for_change&.has_key?(value)
              record = polymorphic_new(data_for_change[value])
              render_link(record)
            else
              value
            end
          end

          def polymorphic_new(attrs)
            a = (target_klass || attrs['type']&.safe_constantize)
            return a&.polymorphic_new(attrs)
          end

          def target_klass
            klass.reflect_on_association(assoc_name)&.klass
          end

          def assoc_name
            @assoc_name ||= klass.reflect_on_association_from_method_name(field_name)&.name
          end

          def render_link(e, options = {})
            item_link(e, options) do
              photo_tag(record_photo(e), e.class.try(:icon))
              record_name(e)
            end
          end

          def item_link(e, options = {})
            Link(url_for(record: e, action: 'edit'), options.merge('data-open-panel' => 'opposite')) do
              yield
            end.on(:click) do |event|
              event.stop_propagation
            end
          end

          def photo_tag(photo, fallback_icon)
            signed_id = photo&.attachment&.signed_id
            @photo_errors ||= {}
            if signed_id && !@photo_errors[signed_id]
              IMG({
                src: "#{::HyperResource::Base.api_prefix}/files/representations/#{signed_id}/icon/icon.png",
                class: 'item-icon mr-1',
                onError: Proc.new{ @photo_errors[signed_id] = true; mutate }
              })
            else
              SPAN(class: 'item-icon mr-1') do
                I(class: "fas fa-#{fallback_icon} fa-inverse"){}
              end
            end
          end

          def record_name(r)
            r.try(r&.class.try(:name_attribute) || 'name')
          end

          def record_photo(r)
            r.try(r&.class.try(:photo_attachment) || 'photo')
          end

          def removed # manage belongs_to and has_many the same way in order to manage changes of type of associations
            case change
            when ::Hash
              Array(change[:removed])
            when ::Array
              Array(change[0])
            end
          end

          def added
            case change
            when ::Hash
              Array(change[:added])
            when ::Array
              Array(change[1])
            end
          end

          render do
            removed.each do |value|
              value_layout('danger') do
                render_value(value)
              end
            end
            added.each do |value|
              value_layout('success') do
                render_value(value)
              end
            end
          end

        end

        class BelongsTo < Base; end
        class HasMany < Base; end
      end

      module Attachment
        class Base < Diff::Base

          def render_link(value)
            signed_id = value
            content_type = data_for_change.dig(signed_id, :content_type)
            filename = data_for_change.dig(signed_id, :filename)
            if filename
              download_path = "#{::HyperResource::Base.api_prefix}/files/blobs/#{signed_id}/#{filename}"
              A(href: download_path, target: "_blank") do
                if content_type&.start_with?('image')
                  @photo_errors ||= {}
                  if !@photo_errors[signed_id]
                    src = "#{::HyperResource::Base.api_prefix}/files/representations/#{signed_id}/photo-button/attachment.png"
                    IMG(
                      src: download_path,
                      class: 'photo-button mr-1',
                      onError: Proc.new{ @photo_errors[signed_id] = true; mutate }
                    )
                  else
                    filename
                  end
                else
                  filename
                end
              end.on(:click) do |event|
                event.stop_propagation
              end
            else
              I18n.t('record_versions.deleted')
            end
          end

        end

        class HasOneAttached < Base

          def render_value(value)
            render_link(value)
          end

        end

        class HasManyAttached < Base

          render do
            change[0]&.each do |value|
              value_layout('danger') do
                render_value(value)
              end
            end
            change[1]&.each do |value|
              value_layout('success') do
                render_value(value)
              end
            end
          end

        end
      end

    end

  end

end
