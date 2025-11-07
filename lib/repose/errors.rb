# frozen_string_literal: true

module Repose
  module Errors
    class Error < StandardError; end
    class ConfigError < Error; end
    class GitHubError < Error; end
    class AIError < Error; end
    class ValidationError < Error; end
  end
end