# frozen_string_literal: true

require "octokit"

module Repose
  class GitHubClient
    def initialize
      token = Repose.config.github_token || ENV.fetch("REPOSE_TOKEN", nil)

      if token.nil? || token.empty?
        raise Errors::ConfigurationError,
              "GitHub token not configured. Set REPOSE_TOKEN environment variable or run 'repose configure'"
      end

      @client = Octokit::Client.new(access_token: token)
      @client.auto_paginate = true
    end

    # Returns an array of namespace hashes (personal account + orgs) the
    # authenticated user can create repositories under.  Each element has the
    # shape: { name: "display label", value: "login" }.
    def available_namespaces
      user = @client.user
      orgs = @client.organizations

      namespaces = [{ name: "#{user.login} (personal)", value: user.login }]
      orgs.each do |org|
        namespaces << { name: org.login, value: org.login }
      end

      namespaces
    rescue Octokit::Unauthorized => e
      raise Errors::AuthenticationError, "GitHub authentication failed: #{e.message}"
    rescue Octokit::Error => e
      raise Errors::GitHubError, "Failed to fetch organizations: #{e.message}"
    end

    def create_repository(name:, description:, private: false, topics: [], readme: nil, license: nil, owner: nil)
      repo_options = {
        description: description,
        private: private,
        auto_init: false, # We'll create our own README
        has_issues: true,
        has_wiki: true,
        has_projects: true
      }

      # Add license template only for GitHub-supported keys
      if license && !license.empty?
        normalized = normalize_license_key(license)
        repo_options[:license_template] = normalized if normalized
      end

      # Create under an org when the owner differs from the authenticated user
      repo_options[:organization] = owner unless owner.nil? || owner.empty? || owner == current_user_login

      repo = @client.create_repository(name, repo_options)

      # Add topics if provided
      @client.replace_all_topics(repo.full_name, topics.map(&:downcase).uniq) if topics.any?

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

    def repository_exists?(name, owner = nil)
      namespace = owner || current_user_login
      @client.repository?("#{namespace}/#{name}")
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

    def create_file(repo_name, path, message, content)
      @client.create_contents(
        repo_name,
        path,
        message,
        content
      )
    rescue Octokit::UnprocessableEntity
      # File might already exist, skip it
      puts "Skipping #{path} (already exists)"
    rescue Octokit::Error => e
      raise Errors::GitHubError, "Failed to create file #{path}: #{e.message}"
    end

    private

    def current_user_login
      @current_user_login ||= @client.user.login
    end

    def normalize_license_key(license)
      # Maps display values to GitHub API license_template keys.
      # Returns nil for licenses GitHub cannot auto-create (BUSL, Elastic, SSPL, EUPL, etc.)
      # so the caller skips setting license_template rather than sending a bad key.
      github_supported = {
        "mit" => "mit",
        "apache" => "apache-2.0",
        "apache-2.0" => "apache-2.0",
        "gpl-2.0" => "gpl-2.0",
        "gpl" => "gpl-3.0",
        "gpl-3.0" => "gpl-3.0",
        "lgpl-2.1" => "lgpl-2.1",
        "lgpl-3.0" => "lgpl-3.0",
        "agpl-3.0" => "agpl-3.0",
        "bsd" => "bsd-3-clause",
        "bsd-2-clause" => "bsd-2-clause",
        "bsd-3-clause" => "bsd-3-clause",
        "mpl" => "mpl-2.0",
        "mpl-2.0" => "mpl-2.0",
        "isc" => "isc",
        "bsl-1.0" => "bsl-1.0",
        "cc0-1.0" => "cc0-1.0",
        "unlicense" => "unlicense"
      }

      github_supported[license.downcase]
    end
  end
end
