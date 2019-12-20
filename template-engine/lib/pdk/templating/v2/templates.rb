require 'pdk/templating/v2/util'
require 'pdk/templating/v2/templates/template_state'

module PDK
  module Templating
    module V2
      module Templates
        # These should be strings not symbols
        # TODO: What about templates that can override file content? e.g. 'template_modification'. How do we handle those?
        TEMPLATE_TYPE_MODULE = 'module'.freeze
        TEMPLATE_TYPES = [TEMPLATE_TYPE_MODULE].freeze

        def self.exist?(template_source, name)
          File.exist?(template_metadata_path(template_source, name))
        end

        def self.template_path(template_source, name)
          File.join(template_source.path, name)
        end

        def self.template_metadata_path(template_source, name)
          File.join(template_source.path, name, 'template.json')
        end

        # Template Factory.  Not that useful right now, but the in future, probably!
        def self.create(template_source, name, logger)
          metadata_path = template_metadata_path(template_source, name)
          raise "Template metadata file #{metadata_path} does not exist" unless File.exist?(metadata_path)
          metadata = Util.read_json_file(metadata_path, logger)

          template_path = File.join(template_source.path, name)

          case metadata['type']
          when TEMPLATE_TYPE_MODULE
            require 'pdk/templating/v2/templates/module_template'
            ModuleTemplate.new(template_source, name, metadata, logger)
          else
            raise "Unknown template type '#{metadata['type']}'"
          end
        end

        def self.template_valid?(template)
          template_validation_errors(template).empty?
        end

        def self.template_validation_errors(template)
          errors = []
          # Validate template type
          errors << "Unknown template type #{template.template_type}" unless TEMPLATE_TYPES.include?(template.template_type)
          # Validate publish_settings
          unless template.metadata['publish_settings'].nil?
            errors << "The metadata for 'publish_settings' should be a hash" unless template.metadata['publish_settings'].is_a?(Hash)
          end
          # Validate setting_subscription
          unless template.metadata['setting_subscription'].nil?
            errors << "The metadata for 'setting_subscription' should be an array" unless template.metadata['setting_subscription'].is_a?(Array)
          end
          # Check for arrays-of-hashes as they can't be knocked out
          template.default_settings.each do |key, value|
            next unless value.is_a?(Array)
            first_hash = value.find { |item| item.is_a?(Hash) }
            errors << "Default setting '#{key}' is an array of hashes which stops the ability for users to knockout values" unless first_hash.nil?
          end
          errors
        end

        def self.render_template_file(absolute_path, template_state)
          raise "#{absolute_path} is not a readable file" unless File.exist?(absolute_path)
          raise "Expected template_state to be an object of type PDK::Templating::V2::Templates::TemplateState but got #{template_state.class}" unless template_state.is_a?(PDK::Templating::V2::Templates::TemplateState)
          content = File.open(absolute_path, 'rb:utf-8') { |f| f.read }

          # Render an ERB file
          return render_erb_template_file(content, absolute_path, template_state) if File.extname(absolute_path).casecmp?('.erb')

          # Default is to return the content verbatim
          content
        end

        # @api private
        def self.render_erb_template_file(content, absolute_path, template_state)
          require 'erb'
          renderer = ERB.new(content, nil, '-')
          # Makes erorr messages make more sense
          renderer.filename = absolute_path

          renderer.result(template_state.get_binding)
        end
      end
    end
  end
end
