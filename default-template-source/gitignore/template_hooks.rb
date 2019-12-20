def before_template_render(state = nil)
  state = self if state.nil?
  state.settings['paths'].concat(['/inventory.yaml']) if state.subscribed_settings['use_litmus']
  state.published_settings['gitignore_paths'] = state.settings['paths']
end
