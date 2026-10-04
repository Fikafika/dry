module Dynamic
  module Experience
    module Owner
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__experience__, klass, concern, mandatory: [:organization, :professional_experiences, :function, :sync])

        conf = klass.const.__experience_config

        owner_klass_id = concern.feature.options.detect {|o| o.name == 'owner_klass'}&.value_string
        concern.feature.concerns.select {|c| c.name.in?(['Job']) && owner_klass_id == klass.id}.each do |c|
          next unless c.options.detect{|o| o.name == 'synchronize'}&.value
          klass.const.include(Synchronizable)
          conf[:organization] = c.options.detect{|o| o.name == 'organization_association'}&.value&.name
          conf[:experiences] = c.options.detect{|o| o.name == 'experiences_association'}&.value&.name
          conf[:function] = c.options.detect{|o| o.name == 'function_attribute'}&.value&.name

          klass.const.define_has_many_callback(:before_add, conf[:experiences], :before_add_experience)
          klass.const.define_has_many_callback(:before_remove, conf[:experiences], :before_remove_experience)
          break
        end
      end

      module Synchronizable; extend ActiveSupport::Concern
        included do
          after_create :init_job_experience, if: :init_job_experience?
          before_update :sync_job_experience, if: :sync_job_experience?

          delegate *[
            :init_job_experience,
            :init_job_experience?,
            :sync_job_experience,
            :sync_job_experience?,
            :before_add_experience,
            :before_remove_experience,
          ], to: :__experience__
        end
      end

      included do
        delegate *[
          :skip_experience_callbacks,
          :skip_experience_callbacks=,
        ], to: :__experience__
      end

      class Proxy < Dynamic::Concern::Proxy
        attr_accessor :skip_experience_callbacks

        def init_job_experience
          create_experience(experience_klass)
        end

        def init_job_experience?
          return !skip_experience_callbacks && (function || organization)
        end

        def sync_job_experience
          k = experience_klass
          exp = most_recent_ongoing_experience
          if !exp
            create_experience(k)
          else
            exp_proxy = exp.__experience__
            if organization_id_changed?(to: nil)
              exp_proxy.skip_experience_callbacks = true
              exp.destroy!
              new_exp = most_recent_ongoing_experience(removing: exp)
              if new_exp
                new_exp.__experience__.organization = organization
                new_exp.__experience__.title = function
                new_exp.__experience__.skip_experience_callbacks = true
                new_exp.save!
              end
            elsif organization_id_changed?
              exp_proxy.organization = organization
              exp_proxy.skip_experience_callbacks = true
              exp.save!
            else
              exp_proxy.organization = organization
              exp_proxy.title = function
              exp_proxy.skip_experience_callbacks = true
              exp.save!
            end
          end
        end

        def sync_job_experience?
          return !skip_experience_callbacks && (function_changed? || organization_id_changed?)
        end

        def experience_klass
          @record.class.reflect_on_association(@config[:experiences].to_sym).klass
        end

        def most_recent_ongoing_experience(removing: nil)
          exps = if removing
            experiences.reject {|e| e.id == removing.id || !e.__experience__.ongoing}
          else
            experiences.select {|e| e.__experience__.ongoing}
          end
          ordered_exps = exps.sort do |a, b|
            a.updated_at <=> b.updated_at
          end

          main_exp = ordered_exps.detect {|e| e.__experience__.main_company}
          return main_exp ? main_exp : ordered_exps.last
        end

        def create_experience(klass)
          experiences.create!(
            skip_experience_callbacks: true,
            "#{klass.__experience_config[:organization]}": organization,
            "#{klass.__experience_config[:title]}": function,
            "#{klass.__experience_config[:ongoing]}": true,
          )
        end

        def remove_main_from_other_experiences(klass)
          experiences.each do |exp_pro|
            next unless exp_pro.__experience__.main_company
            exp_pro.__experience__.main_company = false
            exp_pro.__experience__.skip_experience_callbacks = true
            exp_pro.save!
          end
        end

        def before_add_experience(experience)
          return if organization_id_changed? || function_changed? || !experience.__experience__.ongoing
          exp = most_recent_ongoing_experience
          return if exp && experience.updated_at && (exp.updated_at > experience.updated_at)
          self.function = experience.__experience__.title
          self.organization = experience.__experience__.organization
          self.skip_experience_callbacks = true
        end

        def before_remove_experience(experience)
          return if organization_id_changed? || function_changed?
          main_exp = most_recent_ongoing_experience(removing: experience)
          self.function = main_exp ? main_exp.__experience__.title : nil
          self.organization = main_exp ? main_exp.__experience__.organization : nil
          self.skip_experience_callbacks = true
        end

      end

    end
  end
end
