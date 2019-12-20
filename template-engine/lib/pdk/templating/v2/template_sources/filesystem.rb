require 'pdk/templating/v2/template_sources/base'

module PDK
  module Templating
    module V2
      module TemplateSources
        class Filesystem < Base
          def self.from_hash(logger, hash)
            return nil if hash.nil? || hash['type'] != 'filesystem'
            return nil if hash['location'].nil? || hash['location'].empty?
            Filesystem.new(File.expand_path(hash['location']), logger, hash)
          end

          def initialize(path, logger, options = {})
            raise "#{path} does not exist or is not a directory" unless Dir.exist?(path)
            super
          end
        end
      end
    end
  end
end
