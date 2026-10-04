# In production we don't want js source code to be public
# this controller provides original position of js errors

class JsErrorsController < ApplicationController

  before_action :retrieve_original_position, only: [:create, :original_position]
  before_action :log_error_message, only: [:create, :original_position]

  def create
    #TODO store error
    render :json => @original_position || {error: message}, status: :ok
  end

  def original_position
    if @original_position
      render :json => @original_position, status: :ok
    else
      render :json => {message: message}, status: :not_found
    end
  end

  private

  def retrieve_original_position
    @original_position = SourceLocation.new(params[:backtrace]).code_position
  end

  def log_error_message
    Rails.logger.error message
  end

  def message
    if @original_position
      "#{params[:error]} at #{@original_position[:source]}:#{@original_position[:line]}:#{@original_position[:column]}"
    else
      "#{params[:error]}. fail to find source location"
    end
  end

  class SourceLocation

    def initialize(original_backtrace)
      @original_backtrace = original_backtrace
    end

    def code_position
      node_response = ''
      IO.popen("node", "r+") do |pipe|
        pipe.puts original_position_code
        pipe.puts "console.log(JSON.stringify(originalPositionOfFirstBacktraceLine(#{backtrace_with_map.to_json})))"
        pipe.close_write
        while l = pipe.gets do
          node_response += l
        end
      end
      result = JSON.parse(node_response).with_indifferent_access rescue nil
      result[:source] = convert_source_filename(result[:source]) if result
      return result
    end

    private

    def backtrace_with_map
      result = []
      @original_backtrace&.each do |backtrace_line|
        next unless backtrace_line =~ /^http(s)*:/

        l = backtrace_line.split(':')
        t = l.shift
        l[0] = "#{t}:#{l[0]}"

        file = l[0]
        line = l[1].to_i
        column = l[2].to_i

        map = find_source_map_filename(file) # TODO cache
        next unless map

        result << {
          file: sanitize_for_js(file),
          map: sanitize_for_js(map),
          line: sanitize_for_js(line),
          column: sanitize_for_js(column),
        }
      end
      return result
    end

    def find_source_map_filename(js_filename)
      js_filename = file_path_from_public_url(js_filename) if js_filename.start_with?('http')

      unless File.exist?(js_filename)
        Rails.logger.info "unknown #{js_filename}"
        return nil
      end

      # unfortunaly source_map doesn't have same digest as js file due to the way sprockets works
      # moreover we don't want js files to contains sourcemap url that are not accessible due to production env
      # so we must guess source map filename from js file name

      dir = File.dirname(js_filename)
      dir.gsub!(/^public/, source_maps_dir)
      base = File.basename(js_filename)
      base = base.gsub(/(?:\-[^\-]+)*\.js$/, '')

      result = Dir.glob("#{dir}/#{base}-*.js.map").first
      Rails.logger.info "fail to find source_map for #{js_filename}" unless result

      return result
    end

    def file_path_from_public_url(js_filename)
      start_idx = ENV['APP_PATH_PREFIX'].present? ? 4 : 3
      File.join('public', File.join(js_filename.split('/')[start_idx..-1]))
    end

    def original_position_code
      %Q{
        const sourceMap = require('source-map-js')
        const fs = require('fs')
        const path = require('node:path')

        function originalPosition(mapFilename, line, column) {
          const rawSourceMap = fs.readFileSync(mapFilename).toString()
          var consumer = new sourceMap.SourceMapConsumer(rawSourceMap)
          const intermediatePos = consumer.originalPositionFor({line: line, column: column})
          const sectionsFile = mapFilename.replace(/\.map$/, '.sections')
          const sections = JSON.parse(fs.readFileSync(sectionsFile).toString())

          var i
          for(i = 0; i < sections.length; i ++){
            if ((intermediatePos.line >= sections[i].offset.line) && ((i === sections.length - 1) || intermediatePos.line < sections[i + 1].offset.line)) {
              consumer = new sourceMap.SourceMapConsumer(sections[i].map)
              l = intermediatePos.line - sections[i].offset.line
              if (l > 0) {
                var pos = consumer.originalPositionFor({line: l, column: column})
                return pos
              } else {
                return null
              }
            }
          }
          return null
        }

        function originalPositionOfFirstBacktraceLine(backtrace) {
          const sourceBlacklist = [
            /corelib/,
            /auto-import/,
            /hyperstack\\/internal/,
            /active\_support\\/core_ext\\/object/,
          ]
          var pos
          var l
          var i
          for(i = 0; i < backtrace.length; i++){
            l = backtrace[i]
            pos = originalPosition(l.map, l.line, l.column)
            if (pos && pos.source && !sourceBlacklist.find((r) => { return pos.source.match(r) })) {
              return pos;
            }
          }
          return null
        }
      }
    end

    def source_maps_dir
      'source_maps'
    end

    def sanitize_for_js(s)
      case s
      when Integer
        s
      when String
        [';', ',', '"', "'", "\\"].detect{|c| s.include?(c) } ? nil : s
      else
        nil
      end
    end

    def convert_source_filename(filename)
      return unless filename
      if filename.end_with?('.source.rb')
        # TODO find why sprockets rename source
        return "/frontend/app/hyperstack/#{filename.gsub(/\.source\.rb$/, '.rb')}"
      else
        return filename
      end
    end
  end


end
