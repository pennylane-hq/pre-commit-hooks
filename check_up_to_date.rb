#! /usr/bin/env ruby

require 'yaml'

hooks = YAML.safe_load_file('.pre-commit-hooks.yaml')
local_config = YAML.safe_load_file('.pre-commit-config.yaml')
  .fetch('repos')
  .find { _1['repo'] == 'local' }
  .fetch('hooks')[1..]
local_config.each { _1.delete('args') }

raise "Update local configuration to include all hooks defined in this repo" unless hooks == local_config
