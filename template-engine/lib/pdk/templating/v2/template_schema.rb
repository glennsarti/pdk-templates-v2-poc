require 'json-schema'

module PDK
  module Templating
    module V2
      # A basic wrapper for JSON Schema
      class TemplateSchema
        def self.template_schema_file(template)
          File.join(template.path, 'template_schema.json')
        end

        def self.create(template, logger)
          schema_file = template_schema_file(template)

          # Get the schema as a JSON document, either from disk, or from the template default settings
          schema_hash = File.exist?(schema_file) ? Util.read_json_file(schema_file, logger) : infer_schema(template)

          # Inject schema info to keep it simple
          schema_hash['$schema'] = "http://json-schema.org/draft-04/schema#"
          schema_hash['$id'] = "http://puppet.com/schema/does_not_exist.json"
          # Don't allow additional properties
          schema_hash['additionalProperties'] = false if schema_hash['additionalProperties'].nil?

          TemplateSchema.new(JSON::Schema.new(schema_hash, 'http://puppet.com/schema/does_not_exist.json'))
        end

        # Infers a JSON Schema from a Template
        #
        # @param template PDK::Templating::V2::Templates::BaseTemplate
        # @api private
        # @return Hash
        def self.infer_schema(template)
          # We only use draft-04 because json-schema gem is SOOO old ... And we don't need the fancy stuff anyway
          schema_hash = {
            '$schema'              => 'http://json-schema.org/draft-04/schema#',
            '$id'                  => 'http://puppet.com/schema/does_not_exist.json',
            'type'                 => 'object',
            'title'                => "The #{name} Template Schema",
            'properties'           => {},
            'definitions'          => {},
            'additionalProperties' => false
          }

          template.default_settings.each do |name, value|
            schema_property = {
              '$id'         => "#/properties/#{name}",
              'description' => "#{name} template setting"
            }

            # Do a basic inference on the type
            case value
            when TrueClass, FalseClass
              schema_property['type'] = 'boolean'
            when Array
              schema_property['type'] = 'array'
              #schema_property['items'] = { 'type' => 'object' }
            when String
              schema_property['type'] = 'string'
            when Integer, Float
              schema_property['type'] = 'number'
            when Hash
              schema_property['type'] = 'object'
            else
              # Do nothing. Don't enforce a type
            end

            schema_hash['properties'][name] = schema_property
          end
          schema_hash
        end

        # @param schema JSON::Schema
        def initialize(schema)
          @schema_impl = schema
        end

        # @return Hash
        def schema
          @schema_impl.schema
        end

        # Validates a hash (e.g. ::JSON.parse(content)) against the schema
        def validate!(hash)
          begin
            ::JSON::Validator.validate!(@schema_impl.schema,hash)
          rescue JSON::Schema::ValidationError => e
            # TODO: Not very nice error messages. Maybe make them betterer?
            raise
          end
        end
      end
    end
  end
end
