module Dynamic

  class Theme < Base
    class << self
      def api_path
        @api_path ||= [Dynamic::Base.api_prefix, 'dynamic', 'themes'].join('/')
      end

      def name_attribute
        'human_name'
      end

      def exceptions_for_update
        @exceptions_for_update ||= []
      end
    end

    translates :human_name
    globalize_accessors

    belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :themes

    has_one_attached :variables
    has_one_attached :custom

    unless RUBY_ENGINE == 'opal'

      def self.includes_for_compile
        {
          schema: 1,
          variables: { include: { download: 1 } },
          custom: { include: { download: 1 } },
        }
      end

      def sprockets_context
        environment = Sprockets::Railtie.build_environment(Rails.application)
        context = environment.context_class.new(
          environment: environment,
          filename: "/",
          metadata: {},
        )
        return context
      end

      class Compiler

        def self.run
          require 'eventmachine'

          Rails.logger.info "start"

          time = 2

          while(true) do
            begin
              EventMachine.run do
                Rails.logger.info "connect"

                ::Dynamic::Theme.includes(
                  Dynamic::Theme.includes_for_compile
                ).__cable__.subscribe(
                  action: :compile_to_file,
                  on: :instance,
                  user_id: nil,
                )
              end
            rescue StandardError => e
              Rails.logger.info e.message
              Rails.logger.info "reconnect in #{time} seconds"
              sleep time
            end
          end
        end

        def self.compile_all(overwrite = false)
          ::Dynamic::Theme.includes(
            Dynamic::Theme.includes_for_compile
          ).all do |themes|
            themes.each do |t|
              t.compile_to_file(overwrite)
            end
          end
          return
        end

      end

      def compile_to_file(overwrite = false)
        return unless public_path
        return if File.exist?(public_path) && !overwrite
        Rails.logger.info "compile #{public_path}"
        begin
          content = compile
          FileUtils.mkdir_p File.dirname(public_path)
          File.open(public_path, 'w') do |f|
            f.write(content)
          end
          return public_path
        rescue Exception => e
          Rails.logger.error e.message
          Rails.logger.error e.backtrace.join("\n")
        end
      end

      def reload_and_compile_to_file
        reload do
          compile_to_file
        end
      end

      # eg. Dynamic::Theme.includes(Dynamic::Theme.includes_for_compile).where(schema_id: 'uneek').find(3) do |t| puts t.compile; end
      def compile
        render_template([
          self.variables.download,
          '@import "application_";',
          self.custom.download,
        ].join("\n"))
      end

      def render_template(template) # server side
        SassC::Rails::ScssTemplate.new.call(
          environment: Sprockets::Railtie.build_environment(Rails.application),
          filename: '/',
          data: template,
          metadata: {}
        )[:data]
      end

      def application_scss
        render_template('@import "application_";')
      end

    else

      def update_appearance
        return unless self.community_appearance
        App.change_theme(self.path, true)
      end

    end

    def schema_name
      schema ? schema.name.underscore : self.scope.dig(:where, :schema_id)
    end

    def public_path
      return @public_path if @public_path
      return unless schema_name
      timestamp = self.updated_at.to_s.gsub(/\.|-|:|Z|T/, '')
      @public_path = "public/themes/#{schema_name}/#{self.id}-#{timestamp}.css"
      return @public_path
    end

    def reload
      @public_path = nil
      super
    end

    def path
      "#{ENV['APP_PATH_PREFIX']}#{public_path&.gsub(/^public/, '')}"
    end

  end

end
