#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

@schema = ::Dynamic::Schema.create(name: 'demo')
@klass = @schema.klasses.create({
  human_name_fr: 'Classe',
  human_name_en: 'Klass'
})
Dynamic::Schema.load(@schema.name)

@klass.attrs.create([
  {
    human_name_fr: 'Texte',
    human_name_en: 'String',
    type: 'String'
  },{
    human_name_fr: 'Entier',
    human_name_en: 'Integer',
    type: 'Integer',
  }, {
    human_name_fr: 'Nombre decimal',
    human_name_en: 'Float',
    type: 'Float',
  }, {
    human_name_fr: 'Booleen',
    human_name_en: 'Boolean',
    type: 'Boolean',
  }, {
    human_name_fr: 'Date et heure',
    human_name_en: 'Date time',
    type: 'DateTime',
  }, {
    human_name_fr: 'Date',
    human_name_en: 'Date',
    type: 'Date',
  }, {
    human_name_fr: 'Heure',
    human_name_en: 'Time of day',
    type: 'TimeOfDay',
  }, {
    human_name_fr: 'Liste',
    human_name_en: 'Enum',
    type: 'Enum',
    values_attributes: [
      {
        human_name_fr: 'Choix 1',
        human_name_en: 'Choice 1',
      },
      {
        human_name_fr: 'Choix 2',
        human_name_en: 'Choice 2',
      },
      {
        human_name_fr: 'Choix 3',
        human_name_en: 'Choice 3',
      }
    ]
  },{
    human_name_fr: 'Texte long',
    human_name_en: 'Text',
    type: 'Text'
  },{
    human_name_fr: 'Texte traduit',
    human_name_en: 'Translatable string',
    type: 'TranslatableString'
  },{
    human_name_fr: 'Texte long traduit',
    human_name_en: 'Translatable text',
    type: 'TranslatableText'
  }
])
