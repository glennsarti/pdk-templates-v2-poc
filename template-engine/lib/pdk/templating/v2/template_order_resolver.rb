module PDK
  module Templating
    module V2
      class TemplateOrderResolver
        def initialize(templates)
          @templates = templates

          # We try to preserve the original order so keep a list
          @templates_names = templates.map(&:name)

          # This is a simple dependency graph
          @graph = {}
          templates.each_with_index do |template, index|
            raise "Found duplicate templates: #{template.name}" unless @graph[template.name].nil?
            @graph[template.name] = {
              template: template,
              resolved: false,
              depends_on: []
            }
          end
        end

        def resolve(logger)
          return @template_order unless @template_order.nil?
          # Calculate which templates have which published settings
          # Template order is important here as usual
          setting_list = {}
          @templates.each do |template|
            template.setting_publications.each do |name, _|
              next if setting_list.key?(name)
              setting_list[name] = template.name
            end
          end

          # Now we can calculate the extension dependencies based on setting subscriptions
          @graph.values.each do |item|
            item[:template].setting_subscriptions.each do |sub_setting|
              sub_template = setting_list[sub_setting]
              if sub_template.nil?
                logger.info("Template #{item[:template].name} subscribes to setting #{sub_setting} which is not published")
                next
              end
              item[:depends_on] << sub_template unless item[:depends_on].include?(sub_template)
            end
          end

          resolution = []
          # Basic dependency walker.
          # Keep iterating over all nodes in the graph, marking nodes as resolved, when all of the dependant nodes are resolved.
          # There are probably MUCH better ways to do this but, for the moment this will do, due to the shallow depth and small node count (< 50) expected
          loop do
            did_somthing = false
            @templates_names.each do |name|
              item = @graph[name]
              next if item[:resolved]

              #is_resolved = true
              missing_dep = item[:depends_on].find { |dep_templ| !@graph[dep_templ][:resolved] }
              if missing_dep.nil? || missing_dep.empty?
                item[:resolved] = true
                did_somthing = true
                resolution << name
              end
            end
            break unless did_somthing
          end

          # Check for unresolved templates (Circular dependencies)
          @templates_names.each do |name|
            item = @graph[name]
            next if item[:resolved]
            missing_dep = item[:depends_on].select { |dep_templ| !@graph[dep_templ][:resolved] }
            logger.warn("Template #{item[:template].name} could not be resolved due to circular dependencies on #{missing_dep.join(', ')}")
            resolution << name
          end

          @template_order = resolution.map.with_index { |name, index| [name, index] }.to_h
          @template_order.freeze
        end

        def to_s
          mini_graph = @graph.values.map { |item| { name: item[:template].name, depends_on: item[:depends_on], resolved: item[:resolved] } }
          "#<#{self.class}:#{object_id}> #{mini_graph.inspect}"
        end
      end
    end
  end
end
