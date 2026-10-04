module Dynamic
  module DocumentManagement
    module RegularFile
      extend ActiveSupport::Concern

      included do
        before_save :assign_name_from_asset, if: :assign_name_from_asset?
      end

      def assign_name_from_asset
        self.name = self.asset.try(:filename)
      end

      def assign_name_from_asset?
        attachment_changes['asset']
      end
    end
  end
end
