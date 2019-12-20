# pdk-templates-v2-poc
PDK Templating Engine V2 POC

Proof of concept for PDK Template Engine V2

https://github.com/puppetlabs/pdk-planning/pull/54

**WARNING** Expect history to be re-written and many other bad git history things to happen.  I would suggest not forking this repo!!


``` text
bundle exec rake render

bundle exec rake list-templates

bundle exec rake "list-templates['ci']"

bundle exec rake "show-template['gitignore']"
```

## TODO

- [x] Knockout / ~~Knockin~~ settings
- [x] Warn if a template has default settings which can't be 'knocked-out'
- [x] Has a template validation system
- [x] Warns if template files (e.g. ERB) try to access settings which are not listed in the default settingss
- [ ] Rudementary tests?
- [x] List templates from tag
- [x] Setting validation
- [x] List template info from rakefile
- [ ] Init_files vs regular files? (Sounds like a different renderer/engine?)
