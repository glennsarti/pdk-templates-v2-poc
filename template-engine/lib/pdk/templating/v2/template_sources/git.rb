require 'pdk/templating/v2/template_sources/base'

module PDK
  module Templating
    module V2
      module TemplateSources
        class Git < Base
          def self.from_hash(logger, hash)
            return nil if hash.nil? || hash['type'] != 'git'
            return nil if hash['location'].nil? || hash['location'].empty?
            options = { 'ref' => 'master' }.merge(hash)
            Git.new(logger, options)
          end

          def initialize(logger, options = {})
            # TODO: Determine a local on-disk path
            # path = some_deterministic_path
            # TODO: Git clone if it doesn't already exist
            # TODO: Git checkout the ref
            raise "Not Implemented"

            raise "#{path} does not exist or is not a directory" unless Dir.exist?(path)
            super(path, logger, options = {})
          end
        end
      end
    end
  end
end
