module Dynamic
  module Experience
    module Base
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      module FinishPrevious
        extend ActiveSupport::Concern

        included do
          delegate *[
            :finish_previous_async,
            :finish_previous?,
          ], to: :__experience__

          after_commit :finish_previous_async, on: :create, if: :finish_previous?
        end
      end

      module Synchronizable
        extend ActiveSupport::Concern

        included do
          delegate *[
            :recopy_title_organization,
            :recopy_title_organization?,
            :sync_function_and_organization?,
            :update_owner_function_and_organization,
            :update_owner_before_destroy?,
          ], to: :__experience__

          after_create :recopy_title_organization, if: :recopy_title_organization?
          after_update :recopy_title_organization, if: :sync_function_and_organization?
          before_destroy :update_owner_function_and_organization, if: :update_owner_before_destroy?, prepend: true
        end
      end

      included do
        delegate *[
          :skip_experience_callbacks,
          :skip_experience_callbacks=,
          :init_ongoing,
          :init_main_company,
          :set_ongoing,
          :did_end_date_changed?,
          :set_end_date,
          :did_ongoing_changed?,
          :remove_main_company,
          :remove_main_company?,
          :remove_main_company_from_other_experiences,
          :remove_main_company_from_other_experiences?,
        ], to: :__experience__

        before_create :init_ongoing
        before_create :init_main_company

        before_update :set_ongoing, if: :did_end_date_changed?
        before_update :set_end_date, if: :did_ongoing_changed?
        before_update :remove_main_company, if: :remove_main_company?

        after_save :remove_main_company_from_other_experiences, if: :remove_main_company_from_other_experiences?
      end

      class Proxy < Dynamic::Concern::Proxy
        attr_accessor :skip_experience_callbacks

        def init_ongoing
          self.ongoing = false if end_date
          if ongoing.nil?
            self.ongoing = true
            self.end_date = nil
          end
        end

        def init_main_company
          self.main_company = ongoing && main_company
        end

        def finish_previous_async
          perform_params = {
            klass_name: @record.class.name,
            id: @record.id,
            date_current: Date.current.to_s,
            user_id: User.current&.id,
          }.deep_stringify_keys
          Dynamic::Experience::Worker::FinishPrevious.perform_async(perform_params)
        end

        def finish_previous?
          return finish_previous
        end

        def set_ongoing
          self.ongoing = end_date.nil?
        end

        def did_end_date_changed?
          !skip_experience_callbacks && end_date_changed?
        end

        def set_end_date
          if ongoing
            self.end_date = nil
          elsif self.end_date.nil?
            self.end_date = Date.current
          end
        end

        def did_ongoing_changed?
          !skip_experience_callbacks && ongoing_changed?
        end

        def recopy_title_organization
          proxy = owner.__experience__

          if ongoing_previously_changed?(to: false) || end_date_previously_changed?(from: nil)
            target = find_eligible_experience(proxy)
            proxy.function = target.__experience__.title
            proxy.organization = target.__experience__.organization
          else
            proxy.function = title
            proxy.organization = organization
          end

          proxy.skip_experience_callbacks = true
          owner.save!
        end

        def find_eligible_experience(proxy)
          ordered_exps = proxy.experiences.sort do |a, b|
            a.updated_at <=> b.updated_at
          end

          ordered_exps.each do |e|
            next if e.id == @record.id
            return e if e.__experience__.ongoing
          end

          return ordered_exps.last
        end

        def recopy_title_organization?
          return ongoing_previously_changed?(to: true) && has_owner_no_other_main_company_experiences?
        end

        def remove_main_company
          self.main_company = false
        end

        def remove_main_company?
          return main_company && (ongoing == false) && !skip_experience_callbacks
        end

        def has_owner_no_other_main_company_experiences?
          return owner && owner.__experience__.experiences.none? {|exp| exp == @record ? false : exp.__experience__.main_company}
        end

        def remove_main_company_from_other_experiences
          owner.__experience__.experiences.each do |exp_pro|
            next unless main_company && (exp_pro.id != @record.id)
            exp_pro.__experience__.main_company = false
            exp_pro.__experience__.skip_experience_callbacks = true
            exp_pro.save!
          end
        end

        def remove_main_company_from_other_experiences?
          return owner && main_company && ongoing && !skip_experience_callbacks
        end

        def function_and_organization_sync?
          proxy = owner.__experience__
          return (proxy.function == title) && (proxy.organization && proxy.organization.id == organization&.id)
        end

        def sync_function_and_organization?
          return false if skip_experience_callbacks || !owner
          return false if function_and_organization_sync? && !(ongoing_previously_changed?(to: false) || end_date_previously_changed?(from: nil))
          return main_company || ((has_owner_no_other_main_company_experiences? && ongoing) || (ongoing_previously_changed?(to: false) || end_date_previously_changed?(from: nil)))
        end

        def update_owner_function_and_organization
          main_exp = owner.__experience__.most_recent_ongoing_experience(removing: @record)
          owner.__experience__.function = main_exp ? main_exp.__experience__.title : nil
          owner.__experience__.organization = main_exp ? main_exp.__experience__.organization : nil
          owner.__experience__.skip_experience_callbacks = true
          owner.save!
        end

        def update_owner_before_destroy?
          return !skip_experience_callbacks
        end

      end

    end
  end
end
