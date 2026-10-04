require 'sidekiq'

module Sidekiq
  module CustomSignals
    module CLI
      def launch(self_read)
        signal_for_print_loaded_schemas
        super
      end

      def signal_for_print_loaded_schemas
        sig = 'USR1'
        Signal.trap(sig) do
          print_loaded_schemas
        end
      end

      def print_loaded_schemas
        unless Dynamic::Schema.loaded_schemas.any?
          puts "no loaded schema"
        end
        Dynamic::Schema.loaded_schemas.each do |name, schema|
          puts "==================================="
          puts name
          puts "  updated_at: #{schema.updated_at}"
          puts "  object_id: #{schema.object_id}"
          puts "----------------------------------"

          schema_const = "D::#{name}".constantize
          schema_const.constants.each do |c|
            constant = schema_const.const_get(c)
            next if c == :DynamicRecord
            next unless  constant < ::Dynamic::Record::Base
            puts constant.name
            puts ""
            puts "  attributes:"
            puts "    #{constant.dynamic_attribute_types.inspect}"
            puts ""
            puts "  associations:"
            puts "    #{constant.reflect_on_all_associations.select{|r| !(r.name.to_s =~ /\_as\_target|\_association|\_with\_deleted|versions|\_attachment|\_blob/)}.map(&:name).inspect}"
            puts ""
            puts "  attachments:"
            puts "    #{constant.reflect_on_all_attachments.map(&:name).inspect}"
            puts ""
            puts "  options_for_indexed_json:"
            puts "    #{constant.options_for_indexed_json.inspect}"
            if constant.dynamic_formulas.any?
              puts ""
              puts "  dynamic_formulas:"
              constant.dynamic_formulas.each do |k, f|
                puts "    #{k}:"
                puts "      #{f.str}"
              end
            end
            puts "----------------------------------"
          end
        end
      end
    end

    def self.monkey_patch_cli
      require 'sidekiq/cli'
      ::Sidekiq::CLI.prepend(::Sidekiq::CustomSignals::CLI)
    end
  end
end
