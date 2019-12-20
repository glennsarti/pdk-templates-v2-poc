def before_template_render(state = nil)
  state = self if state.nil?
  if state.settings['use_gitignore'] && state.subscribed_settings['gitignore_paths']
    state.settings['paths'].concat(state.subscribed_settings['gitignore_paths']).uniq
  end
end
