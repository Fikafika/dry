module Dynamic
  module Experience
    module Training
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      include Dynamic::Experience::Base

      def self.after_included(klass, concern)
        proxify_concern(:__experience__, klass, concern, mandatory: [:end_date, :ongoing, :finish_previous, :main_company, :title, :organization, :owner])

        c = klass.const.__experience_config

        if concern.options.detect{|o| o.name == 'synchronize'}&.value
          klass.const.include(::Dynamic::Experience::Base::Synchronizable)
        end

        if concern.options.detect{|o| o.name == 'finish_previous'}&.value
          klass.const.include(::Dynamic::Experience::Base::FinishPrevious)
        end

        base_concern = concern.feature.concerns.detect {|c| c.name == 'Experience'}
        c[:end_date] = base_concern.options.detect{|o| o.name == 'end_date_attribute'}&.value&.name
        c[:ongoing] = base_concern.options.detect{|o| o.name == 'ongoing_attribute'}&.value&.name
        c[:finish_previous] = base_concern.options.detect{|o| o.name == 'finish_previous_attribute'}&.value&.name
        c[:main_company] = base_concern.options.detect{|o| o.name == 'main_organization_attribute'}&.value&.name
        c[:title] = base_concern.options.detect{|o| o.name == 'title_attribute'}&.value&.name
        c[:organization] = base_concern.options.detect{|o| o.name == 'organization_association'}&.value&.name
        c[:owner] = base_concern.options.detect{|o| o.name == 'owner_association'}&.value&.name
      end

      class Proxy < Base::Proxy
      end
    end
  end
end
