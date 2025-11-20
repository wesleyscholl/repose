# frozen_string_literal: true

require_relative "ai/gemini_provider"
require_relative "ai/ollama_provider"

module Repose
  class AIGenerator
    attr_reader :provider

    def initialize(provider: nil)
      @provider = select_provider(provider)
    end

    def generate(context)
      {
        name: context[:name],
        description: generate_description(context),
        topics: generate_topics(context),
        readme: generate_readme(context)
      }
    end

    def use_ai?
      !@provider.nil?
    end

    private

    def select_provider(provider_name)
      return nil if provider_name == :none || provider_name == false

      case provider_name&.to_sym
      when :gemini
        AI::GeminiProvider.new if gemini_available?
      when :ollama
        AI::OllamaProvider.new if ollama_available?
      when nil
        # Auto-detect: prefer Gemini, fallback to Ollama, then none
        if gemini_available?
          AI::GeminiProvider.new
        elsif ollama_available?
          AI::OllamaProvider.new
        end
      else
        raise ArgumentError, "Unknown AI provider: #{provider_name}"
      end
    rescue Repose::ConfigurationError, Repose::APIError
      nil # Fallback to template-based generation
    end

    def gemini_available?
      return false unless ENV["GEMINI_API_KEY"]
      
      AI::GeminiProvider.new.available?
    rescue StandardError
      false
    end

    def ollama_available?
      AI::OllamaProvider.new.available?
    rescue StandardError
      false
    end

    def generate_description(context)
      if use_ai?
        @provider.generate_description(context)
      else
        generate_fallback_description(context)
      end
    rescue Repose::APIError, Repose::AuthenticationError
      generate_fallback_description(context)
    end

    def generate_topics(context)
      if use_ai?
        @provider.generate_topics(context)
      else
        generate_fallback_topics(context)
      end
    rescue Repose::APIError, Repose::AuthenticationError
      generate_fallback_topics(context)
    end

    def generate_readme(context)
      if use_ai?
        @provider.generate_readme(context)
      else
        generate_fallback_readme(context)
      end
    rescue Repose::APIError, Repose::AuthenticationError
      generate_fallback_readme(context)
    end

    def generate_fallback_description(context)
      # Fallback description generation without AI
      base_desc = "A #{context[:language]}"
      base_desc += " #{context[:framework]}" if context[:framework]
      base_desc += " project"
      base_desc += " for #{context[:purpose]}" if context[:purpose] && !context[:purpose].empty?
      
      base_desc.capitalize
    end

    def generate_fallback_topics(context)
      # Basic topic generation without AI
      topics = []
      topics << context[:language].downcase if context[:language]
      topics << context[:framework].downcase if context[:framework]
      
      # Add some common topics based on name patterns
      name_lower = context[:name].downcase
      topics << "api" if name_lower.include?("api")
      topics << "web" if name_lower.include?("web") || context[:framework]&.downcase&.include?("rails")
      topics << "cli" if name_lower.include?("cli") || name_lower.include?("command")
      topics << "tool" if name_lower.include?("tool") || name_lower.include?("util")
      
      topics.uniq.first(8)
    end

    def generate_fallback_readme(context)
      title = context[:name].split(/[-_]/).map(&:capitalize).join(" ")
      
      <<~README
        # #{title}

        A #{context[:language]} #{context[:framework] ? "#{context[:framework]} " : ""}project#{context[:purpose] && !context[:purpose].empty? ? " for #{context[:purpose]}" : ""}.

        ## Installation

        ```bash
        git clone https://github.com/yourusername/#{context[:name]}.git
        cd #{context[:name]}
        ```

        #{language_specific_install_instructions(context[:language])}

        ## Usage

        More documentation coming soon!

        ## Contributing

        1. Fork the repository
        2. Create a feature branch
        3. Make your changes
        4. Submit a pull request

        ## License

        This project is licensed under the MIT License.
      README
    end

    def language_specific_install_instructions(language)
      case language&.downcase
      when "ruby"
        "```bash\nbundle install\n```"
      when "python"
        "```bash\npip install -r requirements.txt\n```"
      when "javascript", "typescript"
        "```bash\nnpm install\n```"
      when "go"
        "```bash\ngo mod download\n```"
      when "rust"
        "```bash\ncargo build\n```"
      else
        ""
      end
    end
  end
end