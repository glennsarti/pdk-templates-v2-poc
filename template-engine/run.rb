# # Add the lib folder to the load path
# $LOAD_PATH.unshift(File.join(__dir__, 'lib'))

# puts "Loading the Template Engine..."
# require 'pdk/templating/v2/template_engine'

# module_dir = File.expand_path(File.join(__dir__, '..', 'example-module'))
# default_template_dir = File.expand_path(File.join(__dir__, '..', 'default-template-source'))

# # helpful alias
# V2 = PDK::Templating::V2

# logger = V2.stdout_logger

# # Load the project settings
# puts "Loading the Project Settings..."
# project_settings = V2::TemplateUserSettings.from_yaml_file(File.join(module_dir, '.sync.yml'), logger)

# puts "Loading the default template source..."
# default_source = V2::TemplateSources::Filesystem.new(default_template_dir, logger)

# puts "Setting up the template engine..."
# engine = V2::TemplateEngine.new(default_source, project_settings, logger)

# puts "Rendering..."
# result = engine.render

# result.rendered_files.each do |path, value|
#   puts "------- #{path} --------------"
#   puts value.content
# end
