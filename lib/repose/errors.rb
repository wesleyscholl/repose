# frozen_string_literal: true

module Repose
  module Errors
    class Error < StandardError; end
    class ConfigError < Error; end
    class ConfigurationError < Error; end
    class GitHubError < Error; end
    class AuthenticationError < Error; end
    class AIError < Error; end
    class ValidationError < Error; end
  end

  # Convenience aliases for AI providers at module level
  ConfigurationError = Errors::ConfigurationError
  APIError = Errors::AIError
  AuthenticationError = Errors::AuthenticationError
  RateLimitError = Errors::AIError
end