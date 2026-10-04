# frozen_string_literal: true

# heavily modified version of https://github.com/javier-menendez/sprockets_terser_with_source_maps
# source maps are not exposed in public for security but they are saved in frontend/source_maps in order to be retrieved by js_error controller

require 'sprockets/digest_utils'
require 'terser/compressor'
require 'logger'

module SprocketsTerserWithSourceMaps
  # Custom compressor to generate sourcemaps
  class Compressor < Terser::Compressor
    attr_accessor :logger

    def initialize(options = {})
      @logger = Logger.new($stdout)
      @logger.level = Logger::INFO
      @options = options.merge(Rails.application.config.assets.terser.to_h)
      super(@options)
    end

    def call(input)
      input_options = {
        source_map: { filename: input[:filename] },
      }

      data = input.fetch(:data)
      name = input.fetch(:name)

      compressed_js, map = @terser.compile_with_map(data, input_options)

      sourcemap = JSON.parse(map)
      sourcemap['file'] = "#{name}.js"
      sourcemap_json = sourcemap.to_json

      # Generate sourcemap file
      source_maps_dir = File.join(Rails.root.to_s, 'source_maps', sprockets_assets_folder)

      FileUtils.mkdir_p(source_maps_dir)

      name_with_digest = "#{name}-#{digest(data)}"

      file_path = File.join(source_maps_dir, "#{name_with_digest}.js.map")

      logger.info "Writing #{file_path}" if !File.exist?(file_path) && file_path.include?('.map')

      File.write(file_path, sourcemap_json)

      # generated sourcemap allow to find original position in js before compression/mangle
      # it doesn't allow to find original position in files combined in this js file
      # so with save position of original files:
      file_path = File.join(source_maps_dir, "#{name_with_digest}.js.sections")
      File.write(file_path, sections_json(input))

      { data: compressed_js, map: sourcemap }
    end

    def sections_json(input)
      input.dig(:metadata, :map, 'sections').to_json
    end

    def sprockets_assets_folder
      'assets'
    end

    private

    def digest(io) # TODO find a way to have same digest as final js
      Sprockets::DigestUtils.pack_hexdigest Sprockets::DigestUtils.digest(io)
    end
  end
end
