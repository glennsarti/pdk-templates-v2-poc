require 'logger'
require 'pdk/templating/v2/template_sources'
require 'pdk/templating/v2/template_user_settings'
require 'pdk/templating/v2/templates'
require 'pdk/templating/v2/template_rendition'
require 'pdk/templating/v2/template_order_resolver'
require 'pdk/templating/v2/published_setting_state'
require 'pdk/templating/v2/hook_manager'

module PDK
  module Templating
    module V2
      def self.stdout_logger
        ::Logger.new($stdout)
      end

      def self.null_logger
        ::Logger.new(File.open(File::NULL, 'w'))
      end

      class TemplateEngine
        attr_reader :options

        attr_reader :logger

        # @option options :template_type The type of templates to render. Default is Template.TEMPLATE_TYPE_MODULE
        def initialize(default_template_source, template_user_settings, logger, options = {})
          raise "Expected an object of type PDK::Templating::V2::TemplateSources::Base but got #{default_template_source.class}" unless default_template_source.is_a?(PDK::Templating::V2::TemplateSources::Base)
          raise "Expected an object of type PDK::Templating::V2::TemplateUserSettings but got #{template_user_settings.class}" unless template_user_settings.is_a?(PDK::Templating::V2::TemplateUserSettings)
          raise "Template User Settings are not valid for this Template Engine" unless template_user_settings.valid?
          @options = options
          @logger = logger
          @default_template_source = default_template_source
          @template_user_settings = template_user_settings
        end

        def settings
          @template_user_settings.settings
        end

        def template_type
          @template_type ||= options[:template_type] || Templates::TEMPLATE_TYPE_MODULE
        end

        # @option options :append_default_source Automatically append the default source at the end of the sources list if it doesn't already exist. Default is true
        # @option options :validate_before_render Validate the settings are valid before rendering a template. Default is true
        def render(options = {})
          options = {
            append_default_source: true,
            validate_before_render: true
          }.merge(options)

          # Verify and find template sources
          sources = template_sources(options[:append_default_source])

          raise "There are no Template Sources defined in the Template User Settings" if sources.empty?
          invalid_sources = sources.select { |source| !source.valid? }
          raise "Found invalid template sources: #{invalid_sources.join(', ')}" unless invalid_sources.nil? || invalid_sources.empty?

          result = TemplateRendition.new

          # "Load" the required templates
          templates = resolved_templates(sources)
          # No templates == Nothing to render
          return result if templates.empty?

          # Verify the templates
          invalid_template = templates.select { |template| !template.valid? }.map(&:name)
          raise "Found invalid templates: #{invalid_template.join(', ')}" unless invalid_template.nil? || invalid_template.empty?

          hooks = HookManager.new(logger)

          # Get the initial published setting state
          published_state = PublishedSettingState.new(templates)

          # Render the templates in order
          templates.each do |template|
            # Create the rendering state
            template_state = Templates::TemplateState.create(template, @template_user_settings, published_state)

            # Optionally validate template settings
            if options[:validate_before_render]
              begin
                template.validate_template_state!(template_state)
              rescue JSON::Schema::ValidationError => e
                # TODO: Could be a lot better
                logger.error("Failed to validate settings for template #{template.name}:\n#{template_state.settings}\n#{e.message}")
                raise
              end
            end

            # Render the template
            result.merge!(template.render(template_state, hooks))

            # Update any published settings
            published_state.update!(template, template_state)
          end

          result
        end

        # @param sources [Array[PDK::Templating::V2::TemplateSource::Base]]
        def templates(sources)
          # We need at least ONE source
          raise "At least one Template Source is required" if sources.nil? || !sources.is_a?(Array) || sources.empty?
          result = []
          loaded_template_names = []

          # Grab all of the requested templates (Template and Source order is important)
          @template_user_settings.requested_templates.each do |template_name|
            next if loaded_template_names.include?(template_name)

            template = nil
            sources.each do |source|
              template = source.templates.find { |templ| templ.name == template_name && templ.template_type == template_type }
              break unless template.nil?
            end
            unless template.nil?
              result << template
              loaded_template_names << template.name
            end
          end

          # Check if we missed anything
          missing_templates = @template_user_settings.requested_templates.select { |name| !loaded_template_names.include?(name) }
          raise "Could not find one or more templates in any sources: #{missing_templates.join(', ')}" unless missing_templates.empty?

          # Now add the always_applied templates if not already done so
          sources.each do |source|
            source.templates.select { |templ| templ.always_apply? }.each do |template|
              next if loaded_template_names.include?(template.name)
              next if @template_user_settings.excluded_templates.include?(template.name)
              result << template
              loaded_template_names << template.name
            end
          end

          result
        end

        # Returns the list of templates, but in resolution order, based on TemplateOrderResolver
        # @param sources [Array[PDK::Templating::V2::TemplateSource::Base]]
        def resolved_templates(sources)
          list = templates(sources)
          # No templates == Nothing to render
          return [] if list.empty?

          resolution_order = TemplateOrderResolver.new(list).resolve(logger)
          # Sort the template array
          list.sort! do |item1, item2|
            resolution_order[item1.name] > resolution_order[item2.name] ? 1 : -1
          end
          list
        end

        # @param sources [Array[PDK::Templating::V2::TemplateSource::Base]]
        def all_templates(sources)
          # We need at least ONE source
          raise "At least one Template Source is required" if sources.nil? || !sources.is_a?(Array) || sources.empty?
          result = []
          loaded_template_names = []

          sources.each do |source|
            source.templates.each do |template|
              next if loaded_template_names.include?(template.name)
              next unless template.template_type == template_type
              result << template
              loaded_template_names << template.name
            end
          end

          result
        end

        def template_sources(auto_append_default_source = nil)
          sources = []
          auto_append_default_source = true if auto_append_default_source.nil?

          if settings['pdk_template']['template_sources'].nil? || settings['pdk_template']['template_sources'].empty?
            return (auto_append_default_source ? [@default_template_source] : [])
          end

          default_added = false
          settings['pdk_template']['template_sources'].each do |raw_source|
            if raw_source == 'default'
              sources << @default_template_source
              default_added = true
              next
            end
            value = TemplateSources.create(logger, raw_source)

            raise "Could not determine the template source from #{raw_source.inspect}" if value.nil?
            sources << value
          end
          sources << @default_template_source if auto_append_default_source && !default_added
          sources
        end
      end
    end
  end
end
