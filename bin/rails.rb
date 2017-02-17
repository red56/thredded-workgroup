#!/usr/bin/env ruby
# frozen_string_literal: true
# This command will automatically be run when you run "rails"
# with Rails 4 gems installed from the root of your application.

ENGINE_ROOT = File.expand_path("../..", __FILE__)
ENGINE_PATH = File.expand_path("../../lib/thredded/workgroup/engine", __FILE__)

# Set up gems listed in the Gemfile.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

require "rails/all"
require "rails/engine/commands"
