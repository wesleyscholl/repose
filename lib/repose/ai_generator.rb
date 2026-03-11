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
        readme: generate_readme(context),
        license: context[:license],
        language: context[:language],
        framework: context[:framework]
      }
    end

    def use_ai?
      !@provider.nil?
    end

    private

    def select_provider(provider_name)
      return nil if [:none, false].include?(provider_name)

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
      # Fallback description generation without AI - with emojis
      emoji = select_emoji_for_language(context[:language])
      purpose_emoji = select_emoji_for_purpose(context[:purpose])

      base_desc = "#{emoji} A #{context[:language]}"
      base_desc += " #{context[:framework]}" if context[:framework]
      base_desc += " project"
      base_desc += " for #{context[:purpose]}" if context[:purpose] && !context[:purpose].empty?
      base_desc += " #{purpose_emoji}" if purpose_emoji

      base_desc.capitalize
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def generate_fallback_topics(context)
      # Enhanced topic generation without AI - generate up to 20 relevant topics
      topics = []
      topics << context[:language].downcase if context[:language]
      topics << context[:framework].downcase if context[:framework]

      # Language ecosystem topics
      language_topics = language_ecosystem_topics(context[:language])
      topics.concat(language_topics)

      # Framework-specific topics
      if context[:framework]
        framework_topics = framework_related_topics(context[:framework])
        topics.concat(framework_topics)
      end

      # Add topics based on name patterns
      name_lower = context[:name].downcase
      topics << "api" if name_lower.include?("api")
      topics << "rest" if name_lower.include?("api") || name_lower.include?("rest")
      topics << "graphql" if name_lower.include?("graphql")
      topics << "web" if name_lower.include?("web") || context[:framework]&.downcase&.match?(/(rails|django|flask|express)/)
      topics << "cli" if name_lower.include?("cli") || name_lower.include?("command")
      topics << "tool" if name_lower.include?("tool") || name_lower.include?("util")
      topics << "library" if name_lower.include?("lib")
      topics << "microservice" if name_lower.include?("micro") || name_lower.include?("service")
      topics << "automation" if name_lower.include?("auto") || name_lower.include?("script")
      topics << "devops" if name_lower.include?("devops") || name_lower.include?("deploy")
      topics << "docker" if name_lower.include?("docker") || name_lower.include?("container")
      topics << "kubernetes" if name_lower.include?("k8s") || name_lower.include?("kube")

      # Purpose-based topics
      if context[:purpose]
        purpose_lower = context[:purpose].downcase
        topics << "ai" if purpose_lower.match?(/(ai|artificial|intelligence|ml|machine|learning)/)
        topics << "data" if purpose_lower.match?(/(data|analytics|etl)/)
        topics << "testing" if purpose_lower.match?(/(test|qa|quality)/)
        topics << "monitoring" if purpose_lower.match?(/(monitor|observ|metric)/)
        topics << "security" if purpose_lower.match?(/(secur|auth|encrypt)/)
      end

      # General best practice topics
      topics.push("opensource", "development", "best-practices")

      topics.uniq.first(20)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def generate_fallback_readme(context)
      title = context[:name].split(/[-_]/).map(&:capitalize).join(" ")
      emoji = select_emoji_for_language(context[:language])
      license = context[:license] || "MIT"
      framework_str = context[:framework] ? "#{context[:framework]} " : ""
      purpose_str = context[:purpose] && !context[:purpose].empty? ? " for #{context[:purpose]}" : ""

      <<~README
        # #{emoji} #{title}

        🚀 A #{context[:language]} #{framework_str}project#{purpose_str}.

        ## ✨ Features

        - 🛠️ Modern #{context[:language]} development
        #{"- 🏛️ Built with #{context[:framework]}" if context[:framework]}
        - 📚 Comprehensive documentation
        - ✅ Production-ready code

        ## 🚀 Installation

        ```bash
        git clone https://github.com/yourusername/#{context[:name]}.git
        cd #{context[:name]}
        ```

        #{language_specific_install_instructions(context[:language])}

        ## 💻 Usage

        More documentation coming soon!

        ## 🤝 Contributing

        1. Fork the repository
        2. Create a feature branch
        3. Make your changes
        4. Submit a pull request

        ## 📄 License

        This project is licensed under the #{license} License.
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

    def select_emoji_for_language(language)
      emojis = {
        "ruby" => "💎",
        "python" => "🐍",
        "javascript" => "⚡",
        "typescript" => "📘",
        "go" => "🚀",
        "rust" => "🦀",
        "java" => "☕",
        "kotlin" => "🎯",
        "swift" => "🍎",
        "php" => "🐘",
        "c" => "⚙️",
        "c++" => "⚙️",
        "c#" => "💠",
        "scala" => "🎸",
        "mojo" => "🔥"
      }
      emojis[language&.downcase] || "🚀"
    end

    def select_emoji_for_purpose(purpose)
      return nil unless purpose && !purpose.empty?

      purpose_lower = purpose.downcase
      case purpose_lower
      when /(api|rest|graphql)/
        "🌐"
      when /(data|analytics|etl)/
        "📊"
      when /(ai|ml|machine|learning)/
        "🤖"
      when /(web|website|frontend)/
        "🎨"
      when /(cli|command|terminal)/
        "💻"
      when /(test|testing|qa)/
        "✅"
      when /(deploy|devops|automation)/
        "⚙️"
      when /(monitor|observ|metric)/
        "📈"
      when /(secur|auth|encrypt)/
        "🔐"
      when /(game|gaming)/
        "🎮"
      when /(chat|message|communication)/
        "💬"
      else
        "✨"
      end
    end

    def language_ecosystem_topics(language)
      topics_map = {
        "ruby" => %w[gem bundler rails ruby-on-rails],
        "python" => %w[pip pypi django flask],
        "javascript" => %w[npm nodejs webpack babel],
        "typescript" => %w[npm nodejs webpack types],
        "go" => %w[golang modules concurrent],
        "rust" => %w[cargo crates systems-programming],
        "java" => %w[maven gradle jvm spring],
        "kotlin" => %w[gradle jvm android],
        "swift" => %w[cocoapods spm ios],
        "php" => %w[composer laravel symfony],
        "c#" => %w[dotnet nuget asp-net],
        "scala" => %w[sbt jvm functional]
      }
      topics_map[language&.downcase] || []
    end

    def framework_related_topics(framework)
      framework_lower = framework&.downcase
      topics = []

      # Web frameworks
      topics.push("web", "mvc", "backend") if framework_lower&.match?(/(rails|django|flask|express|spring)/)
      topics.push("web", "frontend", "spa") if framework_lower&.match?(/(react|vue|angular)/)

      # API frameworks
      topics.push("api", "rest", "microservices") if framework_lower&.match?(/(fastapi|gin|echo|actix)/)

      # Full-stack frameworks
      topics.push("fullstack", "ssr") if framework_lower&.match?(/(next|nuxt)/)

      topics
    end
  end
end
