class Diagram
  attr_writer :diagram_type, :show_label, :alphabetize

  def initialize(options = {})
    @diagram_type = ''
    @show_label   = false
    @alphabetize  = false
    @nodes = []
    @edges = []
    @cluster_names = []
    @node_names = []
    @inclusions ||= {}
    @full_name = options[:full_name]
  end

  def add_node(node)
    @nodes << node unless @nodes.include?(node)
  end

  def add_edge(edge)
    @edges << edge unless @edges.include?(edge)
  end

  def add_inclusion(parent, child)
    @inclusions[parent] ||= []
    @inclusions[parent] << child unless @inclusions[parent].include?(child)
  end

  # Generate DOT graph
  def to_dot
    dot_header +
      root_nodes.map { |n| dot_node n[0], n[1], n[2], n[3] }.join +
      @edges.map { |e| dot_edge e[0], e[1], e[2], e[3] }.join +
      dot_footer
  end

  def root_nodes
    childs = @inclusions.values.flatten.uniq
    @nodes.select{ |n| !childs.include?(n[0]) }.uniq
  end

  # Build DOT diagram header
  def dot_header
    result = "digraph #{@diagram_type.downcase}_diagram {\n" \
             "\tgraph[overlap=false, splines=true, bgcolor=\"white\", compound=true]\n"
    result += dot_label if @show_label
    result
  end

  # Build DOT diagram footer
  def dot_footer
    "}\n"
  end

  # Build diagram label
  def dot_label
    "\t_diagram_info [shape=\"plaintext\", " \
           "label=\"#{@diagram_type} diagram\\l" \
           "Date: #{Time.now.strftime '%b %d %Y - %H:%M'}\\l" +
      (if defined?(ActiveRecord::Migrator)
         'Migration version: ' \
              "#{Rails.logger.silence { ActiveRecord::Migrator.current_version }}\\l"
       else
         ''
       end)
  end

  # Build a DOT graph node
  def dot_node(type, name, attributes = nil, custom_options = '')
    d_name = displayed_name(name)

    if @inclusions[name]&.any?
      type = 'class-with-child' if type == 'class-brief'
    end

    case type
    when 'class'
      options = "shape=record, label=\"{#{d_name}|"
      options += attributes.sort_by { |s| @alphabetize ? s : nil }.join('\l')
      options += '\l}"'
    when 'class-brief'
      options = "shape=box, label=\"#{d_name}\""
      c = node_color(d_name)
      if c.present?
        options += "color=#{c}, fontcolor=#{c}"
      end
    when 'class-with-child'
      attributes ||= []
      attributes << cluster_center(name) if cluster_has_edge?(name)
      @inclusions[name]&.uniq&.each do |child_name|
        n =  @nodes.detect{|n| n[1] == child_name }
        next unless n
        attributes << dot_node(n[0], n[1], n[2], n[3])
      end
      return "subgraph #{cluster_name(name)} {\n\tlabel = #{d_name}\n\tstyle=\"\"#{attributes.join("\n  ")}}\n"
    when 'gem'
      attributes ||= []
      @inclusions[name]&.uniq&.each do |child_name|
        n =  @nodes.detect{|n| n[1] == child_name }
        next unless n
        attributes << dot_node(n[0], n[1], n[2], n[3])
      end
      return "subgraph #{cluster_name(name)} {\n\tlabel = #{quote(name)}\n\tstyle=dotted\n\t#{attributes.join("\n  ")}}"
    end
    options = [options, custom_options].compact.reject(&:empty?).join(', ')
    "\t#{quote(node_name(name))} [#{options}]\n"
  end

  def cluster_name(name)
    @cluster_names << name
    "cluster_#{name.gsub('-', '_').downcase.gsub(/[^a-z0-9\-_]+/i, '_')}"
  end

  def node_name(name)
    @node_names << name
    "node_#{name.gsub('-', '_').downcase.gsub(/[^a-z0-9\-_]+/i, '_')}"
  end

  def cluster_center(name)
    %Q["#{cluster_center_name(name)}" [shape=plain, width=0, height=0, margin=0, fontsize=0, label="."]]
  end

  def cluster_center_name(name)
    cluster_name(name).gsub('cluster_', 'center_of_')
  end

  def cluster_has_edge?(name)
    @edges.detect{|e| e[1] == name || e[2] == name}
  end

  def displayed_name(name)
    @full_name ? name : name.demodulize
  end

  # Build a DOT graph edge
  def dot_edge(type, from, to, name = '')
    edge_color = edge_color(type, from, to, name)
    options =  name.present? ? "label=\"#{name}\", fontcolor=#{edge_color}, " : ''
    case type
    when '<->'
      options += "arrowtail=vee, arrowhead=vee, dir=both color=#{edge_color}"
    when '->'
      options += "arrowtail=none, arrowhead=vee, dir=both color=#{edge_color}"
    when 'is-a'
      options += "arrowtail=empty, arrowhead=none, dir=both color=#{edge_color}"
    end

    if @node_names.include?(from)
      from = node_name(from)
    elsif @cluster_names.include?(from)
      lhead = cluster_name(from)
      from = cluster_name(from).gsub('cluster_', 'center_of_')
      options = %Q[ltail=#{lhead}, ] + options
    end

    if @node_names.include?(to)
      to = node_name(to)
    elsif @cluster_names.include?(to)
      ltail = cluster_name(to)
      to = cluster_name(to).gsub('cluster_', 'center_of_')
      options = %Q[lhead="#{ltail}", ] + options
    end

    "\t#{quote(from)} -> #{quote(to)} [#{options}]\n"
  end

  def edge_color(type, from, to, name)
    if name.present?
      return '"#%02X%02X%02X"' % [rand(255), rand(255), rand(255)]
    elsif from.demodulize == 'Base'
      return '"#DDDDDD"'
    else
      return 'black'
    end
  end

  def node_color(name)
    if name == 'Base'
      return '"#DDDDDD"'
    else
      return 'black'
    end
  end

  # Quotes a class name
  def quote(name)
    "\"#{name}\""
  end
end
