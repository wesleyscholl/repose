# frozen_string_literal: true

require "octokit"

module Repose
  class GitHubClient
    def initialize
      token = Repose.config.github_token || ENV["GITHUB_TOKEN"]
      
      raise Errors::ConfigurationError, "GitHub token not configured. Set GITHUB_TOKEN environment variable or run 'repose configure'" if token.nil? || token.empty?
      
      @client = Octokit::Client.new(access_token: token)
      @client.auto_paginate = true
    end

    def create_repository(name:, description:, private: false, topics: [], readme: nil, license: nil)
      # Create the repository with license template if specified
      repo_options = {
        description: description,
        private: private,
        auto_init: false, # We'll create our own README
        has_issues: true,
        has_wiki: true,
        has_projects: true
      }
      
      # Add license template if specified
      if license && !license.empty?
        repo_options[:license_template] = normalize_license_key(license)
      end
      
      repo = @client.create_repository(name, repo_options)

      # Add topics if provided
      if topics.any?
        @client.replace_all_topics(repo.full_name, topics.map(&:downcase).uniq)
      end

      # Create README if provided
      if readme
        @client.create_contents(
          repo.full_name,
          "README.md",
          "Initial commit: Add README",
          readme,
          branch: repo.default_branch || "main"
        )
      end

      repo
    rescue Octokit::Unauthorized => e
      raise Errors::AuthenticationError, "GitHub authentication failed. Check your token permissions: #{e.message}"
    rescue Octokit::UnprocessableEntity => e
      raise Errors::GitHubError, "Repository creation failed (repository may already exist): #{e.message}"
    rescue Octokit::Error => e
      raise Errors::GitHubError, "GitHub API error: #{e.message}"
    end

    def repository_exists?(name)
      username = @client.user.login
      @client.repository?("#{username}/#{name}")
    rescue Octokit::NotFound
      false
    rescue Octokit::Unauthorized => e
      raise Errors::AuthenticationError, "GitHub authentication failed: #{e.message}"
    end

    def user_info
      @client.user
    rescue Octokit::Unauthorized => e
      raise Errors::AuthenticationError, "Failed to authenticate with GitHub. Check your token: #{e.message}"
    rescue Octokit::Error => e
      raise Errors::GitHubError, "Failed to fetch user info: #{e.message}"
    end

    private

    def normalize_license_key(license)
      # GitHub API uses specific license keys
      license_map = {
        "mit" => "mit",
        "apache" => "apache-2.0",
        "apache-2.0" => "apache-2.0",
        "gpl" => "gpl-3.0",
        "gpl-3.0" => "gpl-3.0",
        "bsd" => "bsd-3-clause",
        "bsd-3-clause" => "bsd-3-clause",
        "mpl" => "mpl-2.0",
        "mpl-2.0" => "mpl-2.0",
        "unlicense" => "unlicense"
      }
      
      normalized = license_map[license.downcase] || license.downcase
      normalized
    end
  end
end