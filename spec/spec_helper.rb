# frozen_string_literal: true

require "bundler/setup"
require "zoho_crm"

require_relative "support/matchers/have_attr"
require_relative "support/matchers/not_change"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Sets a fallback formatter to use if none other has been set.
  config.default_formatter = "progress"
end
