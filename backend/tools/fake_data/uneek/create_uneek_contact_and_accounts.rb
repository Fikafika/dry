#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

::UneekSsoClient.sync_all!

@schema = Dynamic::Schema.where(name: 'Uneek').first

@Contact = @schema.klasses.create!(human_name_fr: 'Contact', human_name_en: 'Contact')

@Contact.attrs.create([
  {
    human_name_fr: 'Nom',
    human_name_en: 'Last name',
    type: 'String',
  },{
    human_name_fr: 'Prénom',
    human_name_en: 'First name',
    type: 'String',
  },{
    human_name_fr: 'Adresse',
    human_name_en: 'Address',
    type: 'String',
  },{
    human_name_fr: 'Courrier électronique',
    human_name_en: 'Email',
    type: 'String',
  },{
    human_name_fr: 'Code postal',
    human_name_en: 'ZIP code',
    type: 'Integer',
  }
])

@Account = @schema.klasses.create!(human_name_fr: 'Compte', human_name_en: 'Account')

@Account.attrs.create([
  {
    human_name_fr: 'Raison sociale',
    human_name_en: 'Name',
    type: 'String',
  }
])

puts "finished"
