module Dynamic
  module Period
    module Feature; extend Dynamic::Feature

      def self.feature_attributes
        {
          # no dependency
          human_name_fr: 'Période',
          human_name_en: 'Period',
          mandatory: false,
          enabled: false,
          concern_templates_attributes: [
            {
              name: 'BelongsToPeriod',
              human_name_fr: 'A une période',
              human_name_en: 'Belongs to a period',
              options_attributes: [
                {
                  name: 'date',
                  human_name_fr: 'Date',
                  human_name_en: 'Date',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'weeky_period',
                  human_name_fr: 'Periode hebdomadaire',
                  human_name_en: 'Weekly period',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'monthly_period',
                  human_name_fr: 'Periode mensuelle',
                  human_name_en: 'Monthly period',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'quarterly_period',
                  human_name_fr: 'Periode trimestrielle',
                  human_name_en: 'Quarterly period',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'half_yearly_period',
                  human_name_fr: 'Periode semestrielle',
                  human_name_en: 'Half yearly period',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'yearly_period',
                  human_name_fr: 'Periode annuelle',
                  human_name_en: 'Yearly period',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
              ],
            },
            {
              name: 'Period',
              human_name_fr: 'Période',
              human_name_en: 'Period',
              options_attributes: [
                {
                  name: 'begin_at',
                  human_name_fr: 'Début',
                  human_name_en: 'Begin at',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'finish_at',
                  human_name_fr: 'Fin',
                  human_name_en: 'Finish at',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'previous_period',
                  human_name_fr: 'Période précédente',
                  human_name_en: 'Previous period',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'week',
                  human_name_fr: 'Semaine',
                  human_name_en: 'Week',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'week_num',
                  human_name_fr: 'Attribut numéro de la semaine',
                  human_name_en: 'Week number attribute',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: true,
                  type: 'String',
                },
                {
                  name: 'month',
                  human_name_fr: 'Mois',
                  human_name_en: 'Month',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'month_num',
                  human_name_fr: 'Attribut numéro du mois',
                  human_name_en: 'Month number attribute',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: true,
                  type: 'String',
                },
                {
                  name: 'quarter',
                  human_name_fr: 'Trimestre',
                  human_name_en: 'Quarter',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'quarter_num',
                  human_name_fr: "Attribut numéro du trimestre",
                  human_name_en: 'Quarter number attribute',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: true,
                  type: 'String',
                },
                {
                  name: 'half_year',
                  human_name_fr: 'Semestre',
                  human_name_en: 'Half year',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'half_year_num',
                  human_name_fr: "Attribut numéro du semestre",
                  human_name_en: 'Number attribute of half year',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: true,
                  type: 'String',
                },
                {
                  name: 'year',
                  human_name_fr: 'Année',
                  human_name_en: 'Year',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  type: 'String',
                },
                {
                  name: 'year_num',
                  human_name_fr: "Attribut numéro de l'année",
                  human_name_en: 'Year number attribute',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: true,
                  type: 'String',
                },
              ],
            },
          ]
        }
      end

    end
  end
end
