# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "zoho_crm/version"

Gem::Specification.new do |spec|
  spec.name = "zoho-crm"
  spec.version = ZohoCRM::VERSION
  spec.authors = ["Robert Audi"]
  spec.email = ["robert.audii@gmail.com"]

  spec.summary = "A gem to make working with Zoho CRM less painful"
  spec.homepage = "https://github.com/Tracktor/zoho-crm"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = ""

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    spec.metadata["changelog_uri"] = "https://github.com/Tracktor/zoho-crm/blob/v#{ZohoCRM::VERSION}/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 2.6"

  spec.add_runtime_dependency "http", "~> 4.1.1"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "~> 0.12"
  spec.add_development_dependency "pry-byebug", "~> 3.7.0"
  spec.add_development_dependency "yard", "~> 0.9.19"
  spec.add_development_dependency "redcarpet", "~> 3.5.0"
  spec.add_development_dependency "github-markup", "~> 3.0.4"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 0.0"
end
