require 'pdk/templating/v2/util'

module PDK
  module Templating
    module V2
      class TemplateUserSettings
        def self.from_yaml_file(path, logger)
          data = Util.read_yaml_file(path, logger)
          TemplateUserSettings.new(logger, data)
        end

        attr_reader :settings

        attr_reader :logger

        def initialize(logger, initial_settings = nil)
          if initial_settings.nil?
            @settings = {}
          else
            raise "Expected an object of type Hash but got #{initial_settings.class}" unless initial_settings.is_a?(Hash)
            @settings = initial_settings
          end
          @logger = logger
        end

        def version_2?
          return false if settings.nil? || settings.empty? || settings['pdk_template'].nil? || settings['pdk_template']['version'].nil?
          settings['pdk_template']['version'] == 2
        end

        def valid?
          version_2?

          # TODO: What about common data structures e.g. settings should be a hash?
        end

        def requested_templates
          return @requested_templates unless @user_requested_templates.nil?
          @requested_templates = []
          unless settings['pdk_template']['templates'].nil?
            @requested_templates = settings['pdk_template']['templates'].select { |name| !name.start_with?('---') }
          end
          @requested_templates.freeze
        end

        def excluded_templates
          return @excluded_templates unless @user_excluded_templates.nil?
          @excluded_templates = []
          unless settings['pdk_template']['templates'].nil?
            @excluded_templates = settings['pdk_template']['templates'].select { |name| name.start_with?('---') }.map { |name| name.slice(3, name.length - 3) }
          end
          @excluded_templates.freeze
        end
      end
    end
  end
end
