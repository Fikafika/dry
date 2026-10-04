#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

 @schema = ::Dynamic::Schema.where(name: 'Demo').first
raise "demo schema doesn't exist" unless @schema
Dynamic::Schema.load(@schema.name)

@klass = @schema.klasses.first

@form = @schema.forms.create!({
  human_name_fr: "Demo edition direct sur deux colonnes",
  human_name_en: "Demo edit in place on two columns",
  actions: [:edit],
  mode: :edit_in_place,
  klass_name: @klass.const_absolute_name,
})

children = []

@klass.attrs.in_groups_of(2).each do |group|
  cols = []
  group.each do |e|
    if e
      if "Dynamic::Form::Element::Attribute::#{e.type}".safe_constantize
        element_type = "Attribute::#{e.type}"
      else
        element_type = "Attribute::String"
      end
      cols << {
        type: 'Layout::Column',
        col_size: 'col-sm-6',
        children_attributes: [{
          root_klass_name: @klass.const_absolute_name,
          klass_name: @klass.const_absolute_name,
          attribute_name: e.name,
          type: element_type,
          label_col_size: 'col-md-4',
          input_col_size: 'col-md-8',
        }]
      }
    else
      cols << {
        type: 'Layout::Column',
        col_size: 'col-sm-6',
      }
    end
  end
  children << {
    type: 'Layout::Row',
    children_attributes: cols
  }
end

@form.elements.create(children)
puts "finish"
