# backtick_javascript: true

class SourceLocation
  include Hyperstack::State::Observable

  @@source_map_from_assets = nil

  attr_reader :error

  def initialize(error)
    @error = error
    @loaded = false
    @loading = false
    @unknown = false
  end

  def unknown?
    !!@unknown
  end

  def loaded?
    !!@loaded
  end

  def column
    load
    return unless @position
    @position[:column]
  end

  def line
    load
    return unless @position
    @position[:line]
  end

  def source
    load
    return unless @position
    @position[:source]
  end

  def in
    load
    return unless @position
    @position[:in]
  end

  def line_with_cursor_from_source
    return [] unless @position[:source]

    if parser_error?
      return [@position[:in]]
    else
      source = source_code(@position)
      return [] unless source
      return line_with_cursor(source, @position)
    end
  end

  private

  def parser_error?
    error.class.name == 'Opal::SyntaxError'
  end

  def load
    return if @loaded || @loading
    @loading = true

    if parser_error?
      @position = code_position
      @loaded = true
      @loading = false
    else
      pos = code_position
      unless pos
        @unknown = true
        @loaded = true
        @loaded = false
        return
      end

      retrieve_original_position(pos) do |original_position|
        @position = original_position
        @loaded = true
        @loading = false
        mutate
      end
    end
  rescue => e
    `console.error('error while retrieving source location', #{e.message})`
  end

  def code_position
    return unless error.try(:backtrace)

    error_line = apply_silencers(error.backtrace).first

    return unless error_line

    if error_line =~ /^http(s)*:/
      l = error_line.split(':')
      t = l.shift
      l[0] = "#{t}:#{l[0]}"
    else
      l = error_line.split(':')
    end
    if l[0].start_with?('app/')
      source = '/frontend/' + l[0]
    else
      source = l[0]
    end

    return {
      source: source,
      line: l[1].to_i,
      column: l[2].to_i,
      in: error_line.split(':in ').last&.gsub(/^`/, '').gsub(/'$/, ''),
    }
  end

  def apply_silencers(backtrace)
    silencers = [
      /method_missing_stub/,
      /Opal\.send/,
      /\$\$exception/,
      /\$raise/,
      /Opal\.type_error/,
      /Opal\.coerce_to/,
      /\$array_slice_index_length/,
      /Array.\$Array_/,
    ]
    backtrace.select do |l|
      l_ = l.strip
      !silencers.detect{|s| l_ =~ s }
    end
  end

  def retrieve_original_position(pos)
    if Hyperstack.env == 'production'
      retrieve_original_position_from_controller do |original_position|
        yield(original_position)
      end
    else
      retrieve_source_map(pos) do |source_map|
        retrieve_original_position_from_source_map(pos, source_map) do |original_position|
          yield(original_position)
        end
      end
    end
  end

  def retrieve_original_position_from_controller
    ::HTTP.post("#{ENV['APP_PATH_PREFIX']}/js_error/original_position.json", payload: {
      error: error.message,
      backtrace: error.backtrace,
    }) do |response|
      if response.ok?
        o = response.json rescue nil
        yield(o) if o
      else
        `console.error(#{response.json.to_n})`
      end
    end
  end

  def retrieve_source_map(position)
    hotloaded_source_map = ::Hyperstack.env != 'production' && ::Hyperstack::Hotloader.source_maps[position[:source]]
    if hotloaded_source_map
      yield(hotloaded_source_map)
    else
      retrieve_source_map_from_assets(position[:source]) do |source_map_from_assets|
        yield(source_map_from_assets)
      end
    end
  end

  def retrieve_source_map_from_assets(js_url)
    if @@source_map_from_assets&.has_key?(js_url)
      return unless @@source_map_from_assets[js_url].present?
      yield(@@source_map_from_assets[js_url])
    end
    @@source_map_from_assets ||= {}
    retrieve_source_map_url_from_assets(js_url) do |map_url|
      if map_url
        ::HTTP.get(map_url, dataType: 'json').then do |r2|
          source_map = r2.json rescue nil
          @@source_map_from_assets[js_url] = source_map
          yield(source_map) if source_map
        end
      else
        @@source_map_from_assets[js_url] = nil
      end
    end
  end

  def retrieve_source_map_url_from_assets(js_url)
    yield("#{js_url}.map")
  end

  def retrieve_original_position_from_source_map(pos, source_map)
    %x{ const consumer = new SourceMapConsumer(#{source_map.to_n}) }
    r = Hash.new(`consumer.originalPositionFor(#{pos.to_n})`)
    if r && r[:source]&.end_with?('.source.rb')
      r[:source] = '/frontend/app/hyperstack/' + r[:source].gsub(/\.source\.rb$/, '.rb')
    end
    yield(r)
  end

  def source_code(position)
    hotloaded_source_map = ::Hyperstack.env != 'production' && ::Hyperstack::Hotloader.source_maps[position[:source]]
    if hotloaded_source_map
      return hotloaded_source_map[:sourcesContent].first
    else
      # TODO find source_code for #{position[:source]}:#{position[:line]}
    end
  end

  def line_with_cursor(source, position)
    line = source.split("\n")[position[:line] - 1]
    cursor = (" " * position[:column] + "^")
    [line, cursor]
  end

end
