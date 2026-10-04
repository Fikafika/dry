require 'components/crm/settings'

class Crm
  class Settings < ::Settings
    include CrmLayout

    render(DIV) { routes }

    def routes
      resource_params = {
        path_prefix: '/crm/:schema_id/settings',
        css_class: 'toolbar-offset-top vh-100-with-offset',
      }

      RouteWithRequest("/crm/:schema_id/settings", exact: true) do |match|
        with_authentication do
          layout_without_toolbar do
            Settings::Schema::Recents(resource_params.merge(match: match))
          end
        end
      end

      RouteWithRequest("/crm/:schema_id/settings/appearance", exact: true) do |match|
        with_authentication do
          layout_without_toolbar do
            Settings::Schema::Appearance(resource_params.merge(match: match))
          end
        end
      end

      [
        Settings::Schema::Klasses,
        Settings::Schema::Features,
        Settings::Schema::Migrations,
        Settings::Schema::Themes,
        Settings::Schema::Redirections,
        Settings::Schema::Permissions,
      ].each do |setting|
        Resources("/crm/:schema_id/settings/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
          layout_without_toolbar do
            setting.create_element(resource_params.merge(match: match))
          end
        end
      end

      [
        Settings::Schema::Klasses::Subklasses,
        Settings::Schema::Attributes,
        Settings::Schema::Associations,
        Settings::Schema::Attachments,
        Settings::Schema::Forms,
        Settings::Schema::Layouts,
        Settings::Schema::DocGen::Templates,
        Settings::Schema::Indexing,
        Settings::Schema::Validations,
        Settings::Schema::MailRules,
        Settings::Schema::Cascades,
        Settings::Schema::Knewsletters,
        Settings::Schema::EmailOrder::Base,
        Settings::Schema::Klasses::Permissions,
        Settings::Schema::ApplicableAmountRules,
        Settings::Schema::Klasses::CopyMappings,
        Settings::Schema::Klasses::CopyMappingsOutgoing,
        Settings::Schema::Klasses::CopyMappingsIncoming,
      ].each do |setting|
        Resources("/crm/:schema_id/settings/klasses/:klass_id/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
          layout_without_toolbar do
            setting.create_element(resource_params.merge(match: match))
          end
        end
      end

      [
        Settings::Schema::Attribute::Values,
        Settings::Schema::Attribute::Validations,
        Settings::Schema::Attribute::Sequences,
        Settings::Schema::Attribute::Styles,
      ].each do |setting|
        Resources("/crm/:schema_id/settings/klasses/:klass_id/attributes/:attr_id/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
          layout_without_toolbar do
            setting.create_element(resource_params.merge(match: match))
          end
        end
      end

      [
        Settings::Schema::Attachment::Variants,
      ].each do |setting|
        Resources("/crm/:schema_id/settings/klasses/:klass_id/attachments/:attachment_id/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
          layout_without_toolbar do
            setting.create_element(resource_params.merge(match: match))
          end
        end
      end

      [
        Settings::Schema::Forms::Cascades,
        Settings::Schema::Forms::Permissions,
      ].each do |setting|
        Resources("/crm/:schema_id/settings/klasses/:klass_id/forms/:form_id/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
          layout_without_toolbar do
            setting.create_element(resource_params.merge(match: match))
          end
        end
      end

      [
        Settings::Schema::Features::Concerns,
      ].each do |setting|
        Resources("/crm/:schema_id/settings/features/:feature_id/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
          layout_without_toolbar do
            setting.create_element(resource_params.merge(match: match))
          end
        end
      end

      [
        Settings::Schema::DocGen::Merge::Files,
        Settings::Schema::DocGen::Permissions,
      ].each do |setting|
        Resources("/crm/:schema_id/settings/klasses/:klass_id/templates/:template_id/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
          layout_without_toolbar do
            setting.create_element(resource_params.merge(match: match))
          end
        end
      end

    end

    def schema
      Dynamic::Schema.load(request.params[:schema_id])
    end

  end

end
