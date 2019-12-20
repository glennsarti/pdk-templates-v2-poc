module PDK
  module Templating
    module V2
      module TemplateSources
        def self.create(logger, hash)
          # TODO: Loop through all of the template sources and see if one
          # can be created from the hash
          nil
        end

        class Base
          attr_reader :path

          attr_reader :options

          attr_reader :logger

          def initialize(path, logger, options = {})
            @path = path
            @options = options
            @logger = logger
          end

          def valid?
            Dir.exist?(path)
          end

          def templates
            return @templates unless @templates.nil?
            @templates = []
            # This is a little pre-optimised searching for '*/template.json'.  Fairly safe to do so.
            Dir.glob(File.join(path, '*/template.json'), File::FNM_DOTMATCH) do |template_json_path|
              next if File.directory?(template_json_path)
              template_dir = File.dirname(template_json_path)
              # Strip the Template Source
              template_dir = template_dir.slice(path.length + 1, template_dir.length - path.length - 1)
              @templates <<  Templates.create(self, template_dir, logger)
            end
            @templates.freeze
          end
        end
      end
    end
  end
end
