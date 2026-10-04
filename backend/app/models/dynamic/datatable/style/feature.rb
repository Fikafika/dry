module Dynamic
  module Datatable
    module Style
      module Feature; extend Dynamic::Feature

        def self.feature_attributes
          {
            human_name_fr: 'Styles de tableau',
            human_name_en: 'Datatable styles',
            mandatory: false,
            concern_templates_attributes: [
              {
                name: 'CellColor',
                human_name_fr: 'Couleur de cellule',
                human_name_en: 'Cell color',
                template: true,
              },
              {
                name: 'RowColor',
                human_name_fr: 'Couleur de ligne',
                human_name_en: 'Row color',
                template: true,
              },
              {
                name: 'ProgressBar',
                human_name_fr: 'Barre de progression',
                human_name_en: 'Progress bar',
                template: true,
              },
              {
                name: 'Badge',
                human_name_fr: 'Badge',
                human_name_en: 'Badge',
                template: true,
              },
              {
                name: 'Icon',
                human_name_fr: 'Icône',
                human_name_en: 'Icon',
                template: true,
              },
              {
                name: 'Button',
                human_name_fr: 'Button',
                human_name_en: 'Button',
                template: true,
              }
            ]
          }
        end

      end
    end
  end
end
