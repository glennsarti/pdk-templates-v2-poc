require 'pdk/templating/v2/templates'

module PDK
  module Templating
    module V2
      class BaseHookManager
        attr_reader :logger

        def initialize(logger)
          @logger = logger
        end

        # @abstract
        def execute(_hook_name, _options = {}); end
      end

      class HookManager < BaseHookManager
        def execute(hook_name, options = {})
          case hook_name
          when :before_template_render
            before_template_render(options[:template], options[:state])
          else
            logger.warn("Unknown hook #{hook_name}")
          end
          nil
        end

        private

        def before_template_render(template, state)
          return if template.nil? || state.nil?
          return unless template.template_hook?('before_template_render')

          # Update the template state
          logger.debug("Executing hook before_template_render from template path #{template.path}...")
          state.instance_eval(template.template_hooks_ruby_string + "\nbefore_template_render", __FILE__, __LINE__)
          nil
        end
      end
    end
  end
end
