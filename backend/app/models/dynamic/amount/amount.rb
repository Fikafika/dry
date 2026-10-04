module Dynamic
  module Amount
    module Amount; extend ActiveSupport::Concern

      def apply_amount(value)
        result = 0
        return result unless value

        if self.percent
          result = value * self.percent
        else
          result = self.raw_value
        end

        return result.round(2)
      end

    end
  end
end
