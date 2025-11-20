# frozen_string_literal: true

require_relative "lib/repose/version"

Gem::Specification.new do |spec|
  spec.name = "reposer"
  spec.version = Repose::VERSION
  spec.authors = ["Wesley Scholl"]
  spec.email = ["wesleyscholl@gmail.com"]

  spec.summary = "AI-powered GitHub repository creation and management"
  spec.description = "Reposer is an intelligent tool that uses AI to create GitHub repositories with smart descriptions, topics, READMEs, and project structure"
  spec.homepage = "https://github.com/wesleyscholl/repose"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wesleyscholl/repose"
  spec.metadata["changelog_uri"] = "https://github.com/wesleyscholl/repose/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = ["reposer"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "octokit", "~> 6.0"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "pastel", "~> 0.8"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "yaml", "~> 0.3"
  spec.add_dependency "ostruct", "~> 0.6"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end