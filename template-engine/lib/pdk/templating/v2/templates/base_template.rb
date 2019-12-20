require 'pdk/templating/v2/util'
require 'pdk/templating/v2/template_schema'

module PDK
  module Templating
    module V2
      module Templates
        class BaseTemplate
          attr_reader :name

          attr_reader :logger

          attr_reader :path

          attr_reader :metadata

          def initialize(template_source, name, metadata, logger)
            @name = name
            @logger = logger
            @path = PDK::Templating::V2::Templates.template_path(template_source, name)
            if metadata.nil?
              metadata_path = PDK::Templating::V2::Templates.template_metadata_path(template_source, name)
              raise "Template metadata file #{metadata_path} does not exist" unless File.exist?(@metadata_path)
              @metadata = Util.read_json_file(metadata_path, logger).freeze
            else
              @metadata = metadata.dup.freeze
            end

            logger.debug("Loading template #{name} from path #{path}")
          end

          def valid?
            PDK::Templating::V2::Templates.template_valid?(self)
          end

          def template_type
            metadata['type'].freeze
          end

          def always_apply?
            # TODO: Do we freeze this?
            metadata['always_apply'] || false
          end

          def description
            # TODO: Do we freeze this?
            metadata['description'] || name
          end

          def default_settings
            metadata['default_settings'].nil? ? {}.freeze : metadata['default_settings'].freeze
          end

          def tags
            metadata['tags'].nil? ? {}.freeze : metadata['tags'].freeze
          end

          def setting_publications
            return @publish_settings unless @publish_settings.nil?
            if metadata['publish_settings'].nil?
              @publish_settings = {}.freeze
            elsif !metadata['publish_settings'].is_a?(Hash)
              logger.warn("Template #{name} from path #{path} does not have a Hash for publish_settings")
              @publish_settings = {}.freeze
            else
              @publish_settings = metadata['publish_settings'].dup.freeze
            end
            @publish_settings
          end

          def setting_subscriptions
           # @setting_subscriptions ||= metadata['setting_subscription'].nil? ? [].freeze : metadata['setting_subscription'].dup.freeze
            return @setting_subscriptions unless @setting_subscriptions.nil?
            if metadata['setting_subscription'].nil?
              @setting_subscriptions = [].freeze
            elsif !metadata['setting_subscription'].is_a?(Array)
              logger.warn("Template #{name} from path #{path} does not have an Array for setting_subscription")
              @setting_subscriptions = [].freeze
            else
              @setting_subscriptions = metadata['setting_subscription'].dup.freeze
            end
            @setting_subscriptions
          end

          def template_hooks_ruby_string
            return @template_hooks_ruby_string unless @template_hooks_ruby_string.nil?
            hooks_file = File.join(path, 'template_hooks.rb')
            @template_hooks_ruby_string = File.exist?(hooks_file) ? File.open(hooks_file, 'rb:utf-8') { |f| f.read } : ''
            @template_hooks_ruby_string.freeze
          end

          def template_hook?(hook_name)
            # Simple, but meh. It works!
            template_hooks_ruby_string.match?(/^\s*def #{hook_name}($|\()/)
          end

          def renderable_template_files
            @renderable_template_files ||= renderable_template_files_impl
          end

          # @return Hash
          def setting_schema
            return @setting_schema unless @setting_schema.nil?
            @setting_schema = TemplateSchema.create(self, logger)
            @setting_schema
          end

          def validate_template_state!(template_state)
            setting_schema.validate!(template_state.settings)
            true
          end

          # @api private
          # @abstract
          def renderable_template_files_impl
            {}
          end

          # @param template_state [PDK::Templating::V2::Templates::TemplateState]
          # @param hook_manager [PDK::Templating::V2::HookManager]
          # @return [TemplateRendition]
          def render(template_state, hook_manager)
            raise "Expected template_state to be an object of type PDK::Templating::V2::Templates::TemplateState but got #{template_state.class}" unless template_state.is_a?(PDK::Templating::V2::Templates::TemplateState)
            raise "Expected hook_manager to be an object of type PDK::Templating::V2::HookManager but got #{hook_manager.class}" unless hook_manager.is_a?(PDK::Templating::V2::HookManager)

            TemplateRendition.new
          end
        end
      end
    end
  end
end
