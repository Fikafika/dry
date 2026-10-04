class Crm
  module Chart
    class BubbleOverlay < Base
      render { content }

      bubble_mixin

      [
        :point,
        :debug,
      ].each { |m| alias_method(m) }

    end
  end
end
