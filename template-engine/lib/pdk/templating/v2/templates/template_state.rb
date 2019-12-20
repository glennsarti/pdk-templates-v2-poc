module PDK
  module Templating
    module V2
      module Templates
        # A hash which will log access to hash keys which do not exist in the frozen state.
        # This is used to detect templates that are using template settings in ERB files which
        # don't exist in the template.json
        class TemplateSettingsHash < Hash
          def initialize(initial_hash, template)
            @logging_keys = nil
            @template = template
            initial_hash.each { |k, v| self[k] = v.dup }
          end

          def freeze
            @logging_keys = self.keys
            super
          end

          def [](key)
            return super if @logging_keys.nil? || @logging_keys.include?(key)
            @template.logger.warn("Template #{@template.name} at path #{@template.path} uses non-default setting #{key}")
            super
          end
        end

        class TemplateState
          def self.create(template, template_user_settings, published_settings)
            raise "Expected template to be an object of type PDK::Templating::V2::Templates::BaseTemplate but got #{template.class}" unless template.is_a?(PDK::Templating::V2::Templates::BaseTemplate)
            raise "Expected template_user_settings to be an object of type PDK::Templating::V2::TemplateUserSettings but got #{template_user_settings.class}" unless template_user_settings.is_a?(PDK::Templating::V2::TemplateUserSettings)
            raise "Expected published_settings to be an object of type PDK::Templating::V2::PublishedSettingState but got #{published_settings.class}" unless published_settings.is_a?( PDK::Templating::V2::PublishedSettingState)

            require 'deep_merge'

            # Set the default render state
            templ_settings = template.default_settings.dup

            # Apply the template user settings using deep merge and knockout prefix
            if template_user_settings.settings[template.name].nil?
              templ_settings = template.default_settings
            else
              # We can't deep-merge directly, so instead create two temporary hashes with the same item name (:settings)
              # and then deep merge those.  Using the knockout prefix of triple hypen
              merged_settings = { settings: template.default_settings.dup }
              merged_settings.deep_merge!({ settings: template_user_settings.settings[template.name] }, knockout_prefix: '---')
              templ_settings = merged_settings[:settings]
            end

            self.new(template, templ_settings, published_settings.masked_state(template), template.setting_publications)
          end

          attr_reader :settings

          attr_reader :subscribed_settings

          attr_reader :published_settings

          # @param settings Hash
          # @param subscribed_settings Hash
          def initialize(template, settings, subscribed_settings, published_settings)
            @settings = TemplateSettingsHash.new(settings, template)
            @subscribed_settings = subscribed_settings.dup
            @published_settings = published_settings.dup
            @published_setting_names = @published_settings.keys
          end

          def freeze!
            @settings.freeze
            @subscribed_settings.freeze
            @published_settings.freeze
          end

          def get_binding
            binding
          end
        end
      end
    end
  end
end
