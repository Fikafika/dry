#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

@uneek = Dynamic::Schema.where(name: 'Uneek').first
raise @uneek.errors.inspect if @uneek.errors.any?



@candidate = @uneek.klasses.create!(human_name_fr: 'Candidat', human_name_en: 'Candidate')

@candidate.attrs.create([
  {
    human_name_fr: 'Nom',
    human_name_en: 'Last name',
    type: 'String',
  },{
    human_name_fr: 'Prénom',
    human_name_en: 'First name',
    type: 'String',
  },{
    human_name_fr: 'Niveau',
    human_name_en: 'Level',
    type: 'Enum',
    values_attributes: [
        { human_name_en: 'level 1', human_name_fr: 'niveau 1' },
        { human_name_en: 'level 2', human_name_fr: 'niveau 2' },
        { human_name_en: 'level 3', human_name_fr: 'niveau 3' },
      ]
  }
])


puts "finished"
