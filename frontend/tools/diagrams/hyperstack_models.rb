#!/usr/local/bin/ruby

require File.expand_path('./capybara.rb', __dir__)

page_load('./diagram.rb')
page_load('./descendants.rb')

page_exec do

  klasses = descendants(HyperResource::Base, ['Module', 'Class', 'Errno', 'Opal', 'D', 'Translation'])

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
    next if c.superclass.name == 'HyperResource::Base'
    @diagram.add_edge ['is-a', c.superclass.name, c.name]
  end

  klasses.each do |k|
    k.reflect_on_all_associations.each do |assoc|
      assoc_type = '->'
      #next if assoc.polymorphic?
      next unless klasses.include?(assoc.klass)

      next unless assoc.instance_variable_get(:@owner_klass) == k

      next if !(k.name == 'Community' || (assoc.klass.name.include?('Dynamic::Schema') && k.name.include?('Dynamic::Schema'))) && (assoc.name == :schema || assoc.options[:inverse_of] == :schema) # too much belongs_to schema

      macro = assoc.is_a?(HyperResource::Reflection::HasManyReflection) ? :has_many : :belongs_to

      next if macro != :has_many && assoc.options[:inverse_of]

      assoc_name = assoc.name

      if macro == :has_many && assoc.options[:inverse_of]
        assoc_name = assoc.name.to_s + "\n / " + assoc.options[:inverse_of].to_s
        assoc_type = "<->"
      end

      @diagram.add_edge [assoc_type, k.name, assoc.klass.name, assoc_name]
    end
  end

end

dot = page_eval("@diagram.to_dot")

filename = 'hyperstack_models'

File.open(filename + '.dot', "w") do |f|
  f.write(dot)
end

system("dot #{filename}.dot -Tsvg > #{filename}.svg")
