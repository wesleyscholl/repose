# frozen_string_literal: true

require "octokit"

module Repose
  class GitHubClient
    def initialize
      @client = Octokit::Client.new(access_token: Repose.config.github_token)
    end

    def create_repository(name:, description:, private: false, topics: [], readme: nil)
      # Create the repository
      repo = @client.create_repository(name, {
        description: description,
        private: private,
        auto_init: false # We'll create our own README
      })

      # Add topics if provided
      if topics.any?
        @client.replace_all_topics(repo.full_name, topics.map(&:downcase))
      end

      # Create README if provided
      if readme
        @client.create_contents(
          repo.full_name,
          "README.md",
          "Initial README",
          readme,
          branch: repo.default_branch
        )
      end

      repo
    rescue Octokit::Error => e
      raise Errors::GitHubError, "GitHub API error: #{e.message}"
    end

    def repository_exists?(name)
      @client.repository?("#{@client.user.login}/#{name}")
    rescue Octokit::NotFound
      false
    end

    def user_info
      @client.user
    rescue Octokit::Error => e
      raise Errors::GitHubError, "Failed to fetch user info: #{e.message}"
    end
  end
end