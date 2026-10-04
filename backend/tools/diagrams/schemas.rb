#!/usr/local/bin/ruby

require File.expand_path('../../config/environment', __dir__)
require File.expand_path('./diagram', __dir__)

Rails.application.eager_load!

Dynamic::Schema.find_each do |s|
  s.load
  filename = s.name.underscore

  @graph = Diagram.new(overlap: 'voronoi') # overlap: 'scale' can also give interesting results. overlap only solve node overlaping problem, not label

  s.klasses.each do |k|
    attrs = k.attrs.map{|a| a.human_name + " : " + a.class.model_name.human}
    record_counts = k.const.count
    @graph.add_node ['class', "#{k.human_name} - #{record_counts}", attrs]
  end

  s.klasses.each do |k|
    k.associations.each do |assoc|
      next unless assoc.target_klass
      assoc_type = '->'
      headlabel = assoc.class.name.ends_with?('HasMany') ? 'n' : '1'
      taillabel = '1'
      @graph.add_edge [assoc_type, k.human_name, assoc.target_klass.human_name, assoc.human_name.downcase, headlabel, taillabel]
    end
  end

  File.open(filename + '.dot', "w") do |f|
    f.write(@graph.to_dot)
  end

  system("dot -Kneato #{filename}.dot -Tsvg > #{filename}.svg")

end
