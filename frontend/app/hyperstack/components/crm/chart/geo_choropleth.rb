class Crm
  module Chart
    class GeoChoropleth < Base
      render { content }

      color_mixin

      [
        :overlay_geo_json,
        :projection,
      ].each { |m| api_method(m) }

      [
        :geo_jsons,
        :geo_path,
        :remove_geo_json,
      ].each { |m| alias_method(m) }

    end
  end
end
