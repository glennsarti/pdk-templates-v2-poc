require 'pdk/templating/v2/templates'
require 'pdk/templating/v2/templates/base_template'
require 'pdk/templating/v2/template_rendition'
require 'pdk/templating/v2/templates/template_state'

module PDK
  module Templating
    module V2
      module Templates
        class RenderableTemplate < BaseTemplate
          # @api private
          def renderable_template_files_impl
            template_files_root = File.expand_path(File.join(path, 'files'))
            template_files_glob = File.join(template_files_root, '**/*')
            result = {}
            Dir.glob(template_files_glob, File::FNM_DOTMATCH) do |absolute_template_file|
              next if File.directory?(absolute_template_file)
              # This may seem a bit naive but there's no reason why this wouldn't work?!
              relative_template_file = absolute_template_file.slice(template_files_root.length + 1, absolute_template_file.length - template_files_root.length - 1)

              # Strip the ERB extension
              if File.extname(relative_template_file).casecmp?('.erb')
                relative_template_file = relative_template_file.slice(0, relative_template_file.length - 4)
              end

              result[relative_template_file] = absolute_template_file
            end
            result
          end

          # @param template_state [PDK::Templating::V2::Templates::TemplateState]
          def render(template_state, hook_manager)
            result = super

            hook_manager.execute(:before_template_render, template: self, state: template_state)

            # Lock the state so ERB rendering etc. can't modify anything.
            # Any changes should come through the the hooks system
            template_state.freeze!

            # Render the files
            renderable_template_files.each do |relative_path, absolute_path|
              logger.debug("Rendering file #{absolute_path}...")
              content = Templates.render_template_file(absolute_path, template_state)
              result.add_rendered_file(RenderedFile.new(relative_path, content))
            end

            result
          end
        end
      end
    end
  end
end
