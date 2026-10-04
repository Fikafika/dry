#!/usr/local/bin/ruby

require File.expand_path('./capybara.rb', __dir__)

page_load('./diagram.rb')
page_load('./descendants.rb')

page_exec do

  klasses = descendants(HyperComponent)

  @diagram = Diagram.new

  klasses.each do |c|
    @diagram.add_node(['class-brief', c.name])
    c_ = c
    while (p = c_.parent) && (p != Object)
      @diagram.add_node(['class-brief', p.name])
      @diagram.add_inclusion(p.name, c_.name)
      c_ = p
    end
  end

  klasses.each do |c|
    next if c.superclass.name == 'HyperComponent'
    @diagram.add_edge ['is-a', c.superclass.name, c.name]
  end

end

dot = page_eval("@diagram.to_dot")

filename = 'hyperstack_components'

File.open(filename + '.dot', "w") do |f|
  f.write(dot)
end

system("dot #{filename}.dot -Tsvg > #{filename}.svg")

