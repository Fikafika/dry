#!/usr/local/bin/ruby

require File.expand_path('../../config/environment', __dir__)
require File.expand_path('./diagram', __dir__)

Rails.application.eager_load!

filename = 'models'

klasses = []
klasses << ActiveRecord::Base
ActiveRecord::Base.descendants.each do |d|
  klasses << d
end

klasses.each do |k|
  klasses << k.superclass unless k.superclass.nil? || k.superclass == Object || klasses.include?(k.superclass)
end

klasses.each do |k|
  k.reflect_on_all_associations.each do |assoc|
    next if assoc.polymorphic?
    klasses << assoc.klass unless klasses.include?(assoc.klass)
  end
end

klasses = klasses.select do |k|
  !k.name.end_with?('::Translation') && !['ActiveRecord::Base', 'ApplicationRecord'].include?(k.name)
end

#puts klasses.map(&:name).inspect

@diagram = Diagram.new(full_name: true)

# draw classes ---------------------------

def klass_attrs(k)
  result = []
  if (k.table_name rescue false)
    k.attribute_names.each do |n|
      t = k.columns_hash[n]&.type.to_s
      unless k.columns_hash[n]
        if k.try(:globalize_attribute_names)&.include?("#{n}_fr".to_sym)
          t = 'translated string'
        end
      end
      result << n + ' : ' + t
    end
  end
  return result
end


def gem_of_a_klass(k)
  gems = Gem::Specification.all_names
  gem_regexp = Regexp.new(gems.map{|g| "(?:gems/#{g})"}.join('|'))

  return nil if $LOADED_FEATURES.detect{|m| !m.include?('/gems/') && m.end_with?("app/models/#{k.name.underscore}.rb") }

  result = nil

  unless result
    l = $LOADED_FEATURES.detect{|m| m.include?('/gems/') && m.end_with?("#{k.name.underscore}.rb")}
    if l
      result = gem_regexp.match(l).try(:[], 0)
    end
  end

  unless result
    if k.name.split('::').length >= 3
      l = $LOADED_FEATURES.detect{|m| m.include?('/gems/') && m.end_with?("#{k.parent.name.underscore}.rb")}
      if l
        result = gem_regexp.match(l).try(:[], 0)
      end
    end
  end

  #unless result
    #(k.instance_methods(true) - k.superclass.instance_methods(true)).each do |m|
      #l = k.instance_method(m).source_location.first;
      #next unless l.end_with?("#{k.name.demodulize.underscore}.rb")
      #result = gem_regexp.match(l).try(:[], 0)
      #break if result
    #end
  #end

  if result
    result.gsub!('gems/', '')
    r = result.split('-')
    r.pop
    result = r.join('-')
  end

  return result
end

klasses_by_gem = {}

klasses.each do |k|
  gem = gem_of_a_klass(k)
  klasses_by_gem[gem] ||= []
  #puts "#{k.name} : #{gem}"
  klasses_by_gem[gem] << k
end

klasses_by_gem.keys.compact.each do |gem|
  @diagram.add_node ['gem', gem]
end

klasses_by_gem.each do |gem, klasses|
  klasses.each do |k|
    @diagram.add_node ['class-brief', k.name]
  end
  if gem
    klasses.each do |k|
      @diagram.add_inclusion(gem, k.name)
    end
  end
end

# draw associations ---------------------------

klasses.each do |k|
  k.reflect_on_all_associations.each do |assoc|
    assoc_type = '->'
    next if assoc.polymorphic?
    next unless klasses.include?(assoc.klass)
    next unless assoc.active_record == k

    next if !(k.name == 'Community' || (assoc.klass.name.include?('Dynamic::Schema') && k.name.include?('Dynamic::Schema'))) && (assoc.name == :schema || assoc.options[:inverse_of] == :schema) # too much belongs_to schema

    next if assoc.macro != :has_many && assoc.options[:inverse_of]

    assoc_name = assoc.name

    if assoc.macro == :has_many && assoc.options[:inverse_of]
      assoc_name = assoc.name.to_s + "\n / " + assoc.options[:inverse_of].to_s
      assoc_type = '<->'
    end

    @diagram.add_edge [assoc_type, k.name, assoc.klass.name, assoc_name]
  end
end

# draw inheritance ----------------------------

klasses.each do |k|
  next unless klasses.include?(k.superclass)
  @diagram.add_edge ['is-a', k.superclass.name, k.name]
end


# --------------------------------------------


File.open(filename + '.dot', "w") do |f|
  f.write(@diagram.to_dot)
end

system("dot #{filename}.dot -Tsvg > #{filename}.svg")

