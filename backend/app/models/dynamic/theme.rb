module Dynamic
  class Theme < ::Dynamic::Schema::Base
    self.table_name = 'dynamic_themes'

    has_many :forms, inverse_of: :theme
    has_many :communities, inverse_of: :theme

    belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :themes

    has_one_attached :variables
    has_one_attached :custom

    concerning :Naming do
      included do
        dynamic_naming paranoid: false

        def transform_name
          return if self.name.blank? || !self.name_changed?
          self.name = I18n.transliterate(self.name).underscore.gsub(/\s/, '_')
        end
      end
    end

    concerning :CommunityAppearance do

      included do
        after_save :update_community_appearance
        after_save :invalidate_forms_and_communities_cache
      end

      def community
        @community ||= Community.find_by_schema_id(self.schema.id)
      end

      def update_community_appearance
        return unless community_appearance_previously_changed?
        if community_appearance
          Dynamic::Theme.where(schema_id: self.schema_id).where.not(id: self.id).update_all(community_appearance: false)
          community&.update(theme_id: self.id)
        else
          community&.update(theme_id: nil) if community.theme_id == self.id
        end
      end

      def invalidate_forms_and_communities_cache
        forms.touch_all
        communities.touch_all
      end

    end

  end
end
