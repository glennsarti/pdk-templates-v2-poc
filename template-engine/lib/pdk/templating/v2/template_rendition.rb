
module PDK
  module Templating
    module V2
      class RenderedFile
        attr_reader :relative_path

        attr_reader :content

        def initialize(relative_path, content)
          @relative_path = relative_path
          @content = content
        end

        def to_s
          "#{@relative_path} = #{@content.length > 20 ? @content.slice(0, 15) + '...' : @content}"
        end
      end

      class TemplateRendition
        attr_reader :rendered_files

        def initialize
          @rendered_files = {}
        end

        def rendered_relative_paths
          @rendered_files.keys
        end

        def add_rendered_file(value)
          @rendered_files[value.relative_path] = value if @rendered_files[value.relative_path].nil?
        end

        def merge!(other_rendition)
          other_rendition.rendered_files.each { |_, value| add_rendered_file(value) }
          self
        end

        def to_s
          "#{self.class}:#{object_id} #{@rendered_files.values.map(&:to_s)}"
        end
      end
    end
  end
end
