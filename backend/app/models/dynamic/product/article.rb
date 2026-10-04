module Dynamic
  module Product
    module Article
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__product__, klass, concern)
      end

      included do
        delegate *[
          :copy_members_from_product,
          :copy_members_from_product?,
          :copy_product_name,
          :copy_product_name?,
        ], to: :__product__

        before_validation :copy_product_name, if: :copy_product_name?
        after_create :copy_members_from_product, if: :copy_members_from_product?
      end

      class Proxy < Dynamic::Concern::Proxy

        def copy_members_from_product
          package_members_attrs = @record.product.package_members.map do |m|
            {
              target_article_attributes: {
                name: m.target_product&.name,
                product: m.target_product
              },
              position: m.position,
              quantity: m.quantity
            }
          end
          @record.package_members.create!(package_members_attrs)
        end

        def copy_members_from_product?
          @record.product && @record.package_members.none?
        end

        def copy_product_name
          @record.name = @record.product.name
        end

        def copy_product_name?
          @record.name.nil? && @record.product
        end

      end

    end
  end
end