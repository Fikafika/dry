module Dynamic

  module Api

    class AddressSearchEngine < Base
      include Dynamic::Mount

      module Feature; extend ::Dynamic::Feature

        def self.feature_attributes
          ase_url = %Q[#{ENV['ASE_PROTOCOL'] || 'http'}://#{ENV['ASE_HOST']}#{":#{ENV['ASE_PORT']}" if ENV['ASE_PORT']}]
          return {
            human_name_fr: "Recherche d'adresse",
            human_name_en: "Address Search",
            mandatory: false,
            options_attributes: [
              {
                name: 'fill_not_in_form_fields',
                human_name_en: 'Fill not in form fields',
                human_name_fr: 'Remplir les champs hors des formulaires',
                type: 'Boolean',
                value: true
              },
            ],
            concern_templates_attributes: [
              {
                name: 'Address',
                human_name_fr: 'Adresse',
                human_name_en: 'Address',
                template: true,
                options_attributes: [
                  {
                    name: 'api_url',
                    human_name_fr: 'URL',
                    human_name_en: 'URL',
                    type: 'String',
                    value: ENV['ASE_HOST'] ? "#{ase_url}/search?options[format]=hash&options[complementary_information]=geographic_coordinates" : nil
                  },
                  {
                    name: 'input_mapping',
                    human_name_en: "Input mapping",
                    human_name_fr: "Données envoyées à l'API",
                    type: 'Hash',
                    value: {
                      q: nil
                    },
                    global: false,
                  },
                  {
                    name: 'output_mapping',
                    human_name_en: 'Output mapping',
                    human_name_fr: "Données à importer dans le CRM",
                    type: 'Hash',
                    value: {
                      street: nil,
                      second_street: nil,
                      third_street: nil,
                      zip_code: nil,
                      city: nil,
                      country_sub_2: nil,
                      country_sub_1: nil,
                      country: nil,
                      latitude: nil,
                      longitude: nil
                    },
                    global: false,
                  }
                ]
              },
              {
                name: 'City',
                human_name_fr: 'Ville',
                human_name_en: 'City',
                template: true,
                options_attributes: [
                  {
                    name: 'api_url',
                    human_name_fr: 'URL',
                    human_name_en: 'URL',
                    type: 'String',
                    value: ENV['ASE_HOST'] ? "#{ase_url}/search?options[format]=hash&options[only]=city" : nil
                  },
                  {
                    name: 'input_mapping',
                    human_name_en: "Input mapping",
                    human_name_fr: "Données envoyées à l'API",
                    type: 'Hash',
                    value: {
                      q: nil
                    },
                    global: false,
                  },
                  {
                    name: 'output_mapping',
                    human_name_en: 'Output mapping',
                    human_name_fr: "Données à importer dans le CRM",
                    type: 'Hash',
                    value: {
                      city: nil,
                    },
                    global: false,
                  }
                ]
              },
              {
                name: 'ZipCode',
                human_name_fr: 'Code Postal',
                human_name_en: 'Zip Code',
                template: true,
                options_attributes: [
                  {
                    name: 'api_url',
                    human_name_fr: 'URL',
                    human_name_en: 'URL',
                    type: 'String',
                    value: ENV['ASE_HOST'] ? "#{ase_url}/search?options[format]=hash&options[only]=zip_code" : nil
                  },
                  {
                    name: 'input_mapping',
                    human_name_en: "Input mapping",
                    human_name_fr: "Données envoyées à l'API",
                    type: 'Hash',
                    value: {
                      q: nil
                    },
                    global: false,
                  },
                  {
                    name: 'output_mapping',
                    human_name_en: 'Output mapping',
                    human_name_fr: "Données à importer dans le CRM",
                    type: 'Hash',
                    value: {
                      zip_code: nil,
                    },
                    global: false,
                  }
                ]
              },
              {
                name: 'State',
                human_name_fr: 'Région',
                human_name_en: 'State',
                template: true,
                options_attributes: [
                  {
                    name: 'api_url',
                    human_name_fr: 'URL',
                    human_name_en: 'URL',
                    type: 'String',
                    value: ENV['ASE_HOST'] ? "#{ase_url}/search?options[format]=hash&options[only]=country_sub_1" : nil
                  },
                  {
                    name: 'input_mapping',
                    human_name_en: "Input mapping",
                    human_name_fr: "Données envoyées à l'API",
                    type: 'Hash',
                    value: {
                      q: nil
                    },
                    global: false,
                  },
                  {
                    name: 'output_mapping',
                    human_name_en: 'Output mapping',
                    human_name_fr: "Données à importer dans le CRM",
                    type: 'Hash',
                    value: {
                      state: nil,
                    },
                    global: false,
                  }
                ]
              },
              {
                name: 'County',
                human_name_fr: 'Département',
                human_name_en: 'County',
                template: true,
                options_attributes: [
                  {
                    name: 'api_url',
                    human_name_fr: 'URL',
                    human_name_en: 'URL',
                    type: 'String',
                    value: ENV['ASE_HOST'] ? "#{ase_url}/search?options[format]=hash&options[only]=country_sub_2" : nil
                  },
                  {
                    name: 'input_mapping',
                    human_name_en: "Input mapping",
                    human_name_fr: "Données envoyées à l'API",
                    type: 'Hash',
                    value: {
                      q: nil
                    },
                    global: false,
                  },
                  {
                    name: 'output_mapping',
                    human_name_en: 'Output mapping',
                    human_name_fr: "Données à importer dans le CRM",
                    type: 'Hash',
                    value: {
                      county: nil,
                    },
                    global: false,
                  }
                ]
              },
              {
                name: 'Country',
                human_name_fr: 'Pays',
                human_name_en: 'Country',
                template: true,
                options_attributes: [
                  {
                    name: 'api_url',
                    human_name_fr: 'URL',
                    human_name_en: 'URL',
                    type: 'String',
                    value: ENV['ASE_HOST'] ? "#{ase_url}/search?options[format]=hash&options[only]=country" : nil
                  },
                  {
                    name: 'input_mapping',
                    human_name_en: "Input mapping",
                    human_name_fr: "Données envoyées à l'API",
                    type: 'Hash',
                    value: {
                      q: nil
                    },
                    global: false,
                  },
                  {
                    name: 'output_mapping',
                    human_name_en: 'Output mapping',
                    human_name_fr: "Données à importer dans le CRM",
                    type: 'Hash',
                    value: {
                      country: nil,
                    },
                    global: false,
                  }
                ]
              },
            ]
          }
        end

        module Address
          def self.load(schema)
            ::Dynamic::Api::AddressSearchEngine.mount(schema)
            return true
          end
        end

        module City
          def self.load(schema)
            ::Dynamic::Api::AddressSearchEngine.mount(schema)
            return true
          end
        end

        module ZipCode
          def self.load(schema)
            ::Dynamic::Api::AddressSearchEngine.mount(schema)
            return true
          end
        end

        module State
          def self.load(schema)
            ::Dynamic::Api::AddressSearchEngine.mount(schema)
            return true
          end
        end

        module County
          def self.load(schema)
            ::Dynamic::Api::AddressSearchEngine.mount(schema)
            return true
          end
        end

        module Country
          def self.load(schema)
            ::Dynamic::Api::AddressSearchEngine.mount(schema)
            return true
          end
        end
      end
    end

  end

end
