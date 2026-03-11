# frozen_string_literal: true

require_relative "repose/version"
require_relative "repose/cli"
require_relative "repose/github_client"
require_relative "repose/ai_generator"
require_relative "repose/config"
require_relative "repose/errors"
require_relative "repose/project_files_generator"

module Repose
  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield config if block_given?
    end
  end
end
