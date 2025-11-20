# frozen_string_literal: true

module Repose
  module Errors
    class Error < StandardError; end
    class ConfigError < Error; end
    class GitHubError < Error; end
    class AIError < Error; end
    class ValidationError < Error; end
  end

  # Convenience aliases for AI providers
  ConfigurationError = Errors::ConfigError
  APIError = Errors::AIError
  AuthenticationError = Errors::AIError
  RateLimitError = Errors::AIError
end