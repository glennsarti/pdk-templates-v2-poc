require 'pdk/templating/v2/templates'

module PDK
  module Templating
    module V2
      class PublishedSettingState
        def include_setting?(setting_name)
          @state.key?(setting_name)
        end

        def initialize(templates)
          raise "An array of templates is required" if templates.nil? || !templates.is_a?(Array)

          @state = {}
          @setting_to_template_id = {}
          templates.each do |template|
            template.setting_publications.each do |name, value|
              next if @state.key?(name)
              @state[name] = value
              @setting_to_template_id[name] = template.object_id
            end
          end
        end

        # Updates the published setting state from a template
        def update!(template, template_state)
          # TODO: Do I check the object types here?!?!
          template_state.published_settings.each do |name, value|
            next unless @setting_to_template_id[name] == template.object_id
            @state[name] = value
            # TODO: logger.info("Updated state")  ??
          end
        end

        # Returns a hash with the published state masked by what settings the template has subscribed to
        # @param template PDK::Templating::V2::Templates::BaseTemplate the template to mask from
        # @return Hash
        def masked_state(template)
          result = {}
          template.setting_subscriptions.each do |name|
            result[name] = @state[name]
          end
          result.dup
        end
      end
    end
  end
end
