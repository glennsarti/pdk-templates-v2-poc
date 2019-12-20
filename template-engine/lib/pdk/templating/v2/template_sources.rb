require 'pdk/templating/v2/template_sources/base'
require 'pdk/templating/v2/template_sources/filesystem'
require 'pdk/templating/v2/template_sources/git'

module PDK
  module Templating
    module V2
      module TemplateSources
        def self.create(logger, hash)
          raise "Template source hash is missing or empty" if hash.nil? || hash.empty?
          case hash['type']
          when 'filesystem'
            return Filesystem.from_hash(logger, hash)
          when 'git'
            return Git.from_hash(logger, hash)
          else
            raise "Unknown template source type #{hash['type']}"
          end
        end
      end
    end
  end
end
