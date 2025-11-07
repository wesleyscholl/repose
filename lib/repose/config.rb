# frozen_string_literal: true

require "yaml"

module Repose
  class Config
    attr_accessor :github_token, :openai_api_key, :default_topics, :default_language

  def initialize
    @default_topics = []
    load_config
  end

  def config_file_path
    File.expand_path("~/.repose.yml")
  end

    def load_config
      return unless File.exist?(config_file_path)

      config = YAML.load_file(config_file_path)
      @github_token = config["github_token"]
      @openai_api_key = config["openai_api_key"]
      @default_topics = config["default_topics"] || []
      @default_language = config["default_language"]
    rescue => e
      warn "Warning: Could not load config file: #{e.message}"
    end

    def save!
      config_hash = {
        "github_token" => @github_token,
        "openai_api_key" => @openai_api_key,
        "default_topics" => @default_topics,
        "default_language" => @default_language
      }.compact

      File.write(config_file_path, YAML.dump(config_hash))
      File.chmod(0600, config_file_path) # Secure the config file
    end

    def valid?
      !@github_token.nil? && !@github_token.empty? &&
        !@openai_api_key.nil? && !@openai_api_key.empty?
    end
  end
end