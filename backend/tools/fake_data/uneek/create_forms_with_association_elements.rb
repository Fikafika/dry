#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

@schema = Dynamic::Schema.where(name: 'Uneek').first

unless @schema
  begin
    ::UneekSsoClient.sync_all!
  rescue SocketError => e
    raise 'sso container is not started ?'
  end

  @schema = Dynamic::Schema.where(name: 'Uneek').first
end

raise 'Uneek schema already have klasses' if @schema.klasses.where(name: 'Contact').first


@Contact = @schema.klasses.create!(name: 'Contact', icon: 'user')
@Company = @schema.klasses.create!({
  name: 'Company',
  icon: 'building',
  attrs_attributes: [{name: 'name', type: 'String'}],
  attachments_attributes: [{name: 'logo', type: 'HasOne'}]
})
@Contact.associations.create(name: 'company', target_klass: @Company, type: 'BelongsTo')
@Contact.associations.create(name: 'companies', target_klass: @Company, type: 'HasMany')

@schema.load

require 'open-uri'

13.times do |i|
  File.open("tmp/#{i + 1}.png", "wb") do |saved_file|
    # the following "open" is provided by open-uri
    open("https://pigment.github.io/fake-logos/logos/medium/color/#{i + 1}.png", "rb") do |read_file|
      saved_file.write(read_file.read)
    end
  end
end

require 'faker'

100.times do
  D::Uneek::Company.create(name: Faker::Company.name, logo: {io: File.open("tmp/#{rand(1..13)}.png"), filename: 'logo.png'})
end

@input_form = @schema.forms.create({
  human_name_fr: 'test nouveau avec associations',
  human_name_en: 'test new with associations',
  klass_name: @Contact.const_absolute_name,
  actions: [:new, :edit],
  mode: :input,
  elements_attributes: [{
    root_klass_name: @Contact.const_absolute_name,
    attribute_name: 'company_id',
    type: 'Association::BelongsTo',
  },{
    root_klass_name: @Contact.const_absolute_name,
    attribute_name: 'company_ids',
    type: 'Association::HasMany',
  }]
})

puts "visit http://dynamo.dev.localhost/crm/#{@schema.name.underscore}/forms/#{@input_form.id}"

@contact = D::Uneek::Contact.create

@edit_in_place_form = @schema.forms.create({
  human_name_fr: 'test edition directe avec associations',
  human_name_en: 'test edit in place with associations',
  actions: [:edit],
  mode: :edit_in_place,
  klass_name: @Contact.const_absolute_name,
  elements_attributes: [{
    root_klass_name: @Contact.const_absolute_name,
    attribute_name: 'company_id',
    type: 'Association::BelongsTo',
  },{
    root_klass_name: @Contact.const_absolute_name,
    attribute_name: 'company_ids',
    type: 'Association::HasMany',
  }]
})

puts "visit http://dynamo.dev.localhost/crm/#{@schema.name.underscore}/forms/#{@edit_in_place_form.id}?source_record_id=#{@contact.id}&source_record_type=#{@contact.class.name}"

13.times do |i|
  FileUtils.rm("tmp/#{i + 1}.png")
end

puts "for check associations in console do:"
puts "Dynamic::Schema.where(name: 'Uneek').first.load"
puts "D::Uneek::Contact.find(#{@contact.id}).company"
puts "D::Uneek::Contact.find(#{@contact.id}).companies"
