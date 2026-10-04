class Crm
  class Planner
    class ConflictState
      include Hyperstack::State::Observable

      def initialize
        @ids = []
        @index = 0
      end

      observer(:ids) { @ids }
      observer(:index) { @index }

      def update(new_ids, new_index)
        mutate do
          @ids = new_ids || []
          @index = new_index
        end
      end
    end
  end
end