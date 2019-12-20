module PDK
  module Templating
    module V2
      module Util
        def self.read_yaml_file(path, _logger)
          raise "File #{path} does not exist or is not a file" unless File.exist?(path)

          content = nil
          begin
            content = File.open(path, 'rb:utf-8') { |f| f.read }
          rescue Errno::ENOENT
            raise
          rescue Errno::EACCES
            raise
          end

          require 'yaml'
          begin
            data = ::YAML.safe_load(content, [Symbol], [], true)
          rescue Psych::SyntaxError => e
            raise ('Syntax error when loading %{file}: %{error}') % {
              file:  path,
              error: "#{e.problem} #{e.context}",
            }
          rescue Psych::DisallowedClass => e
            raise ('Unsupported class in %{file}: %{error}') % {
              file:  path,
              error: e.message,
            }
          end

          data
        end

        def self.read_json_file(path, _logger)
          raise "File #{path} does not exist or is not a file" unless File.exist?(path)

          content = nil
          begin
            content = File.open(path, 'rb:utf-8') { |f| f.read }
          rescue Errno::ENOENT
            raise
          rescue Errno::EACCES
            raise
          end

          require 'json'
          begin
            data = ::JSON.parse(content)
          rescue JSON::ParserError => e
            raise ('Syntax error when loading %{file}: %{error}') % {
              file:  path,
              error: "#{e.message}",
            }
          end

          data
        end
      end
    end
  end
end
