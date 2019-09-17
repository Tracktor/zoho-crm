# frozen_string_literal: true

require "rspec/core/rake_task"
require "yard"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)
YARD::Rake::YardocTask.new

task default: [:spec, :standard]
