class Settings < HyperComponent
  include Hyperstack::Router::Helpers
  include Router::Resources

  render { content }

  def content
    DIV do
      routes
    end
  end

  def routes
    resource_params = {
      path_prefix: '/settings',
      css_class: 'toolbar-offset-top vh-100-with-offset',
    }

    RouteWithRequest("/settings", exact: true) do |match|
      with_authentication do
        Layout() do
          Settings::Recents(resource_params.merge(match: match))
        end
      end
    end

    RouteWithRequest("/settings/schemas/:schema_id/appearance", exact: true) do |match|
      with_authentication do
        Layout() do
          Settings::Schema::Appearance(resource_params.merge(match: match))
        end
      end
    end

    Resources("/settings/schemas(/:#{Settings::Schemas.resource_id_key})") do |match|
      Layout() do
        Settings::Schemas(resource_params.merge(match: match))
      end
    end

    [
      Settings::Schema::Klasses,
      Settings::Schema::Features,
      Settings::Schema::Migrations,
      Settings::Schema::Themes,
      Settings::Schema::Redirections,
    ].each do |setting|
      Resources("/settings/schemas/:schema_id/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
        Layout() do
          setting.create_element(resource_params.merge(match: match))
        end
      end
    end

    [
      Settings::Schema::Attributes,
      Settings::Schema::Associations,
      Settings::Schema::Attachments,
      Settings::Schema::Forms,
      Settings::Schema::Layouts,
    ].each do |setting|
      Resources("/settings/schemas/:schema_id/klasses/:klass_id/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
        Layout() do
          setting.create_element(resource_params.merge(match: match))
        end
      end
    end

    [
      Settings::Schema::Attribute::Values,
    ].each do |setting|
      Resources("/settings/schemas/:schema_id/klasses/:klass_id/attributes/:attr_id/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
        Layout() do
          setting.create_element(resource_params.merge(match: match))
        end
      end
    end

    [
      Settings::Schema::Attachment::Variants,
    ].each do |setting|
      Resources("/settings/schemas/:schema_id/klasses/:klass_id/attachments/:attachment_id/#{setting.resources_name}(/:#{setting.resource_id_key})") do |match|
        Layout() do
          setting.create_element(resource_params.merge(match: match))
        end
      end
    end
  end

  class Schema
  end

end


