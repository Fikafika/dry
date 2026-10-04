class ExternalSource < ApplicationRecord

  translates :human_name, fallbacks_for_empty_translations: true
  accepts_nested_attributes_for :translations, allow_destroy: true
  attribute :human_name, :string
  globalize_accessors

end
