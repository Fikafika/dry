module Dynamic

  module Api

    module AddressSearchEngine

      module Feature

        module Base

          def self.extended(base)
            base.extend ::Dynamic::Api::Concern
          end

        end

        module Address; extend Dynamic::Api::AddressSearchEngine::Feature::Base

          def self.process_results
            Proc.new{|data| data.map{|d| {id: ::HyperResource::Base.generate_uuid, text: d[:label], value: d[:value]}}}
          end

        end

        module City; extend Dynamic::Api::AddressSearchEngine::Feature::Base

          def self.process_results
            Proc.new{|data| data.map{|d| {id: ::HyperResource::Base.generate_uuid, text: d, value: {city: d}}}}
          end

        end

        module ZipCode; extend Dynamic::Api::AddressSearchEngine::Feature::Base

          def self.process_results
            Proc.new{|data| data.map{|d| {id: ::HyperResource::Base.generate_uuid, text: d, value: {zip_code: d}}}}
          end

        end

        module County; extend Dynamic::Api::AddressSearchEngine::Feature::Base

          def self.process_results
            Proc.new{|data| data.map{|d| {id: ::HyperResource::Base.generate_uuid, text: d, value: {county: d}}}}
          end

        end

        module Country; extend Dynamic::Api::AddressSearchEngine::Feature::Base

          def self.process_results
            Proc.new{|data| data.map{|d| {id: ::HyperResource::Base.generate_uuid, text: d, value: {country: d}}}}
          end

        end

        module State; extend Dynamic::Api::AddressSearchEngine::Feature::Base

          def self.process_results
            Proc.new{|data| data.map{|d| {id: ::HyperResource::Base.generate_uuid, text: d, value: {state: d}}}}
          end

        end

      end

    end

  end

end
