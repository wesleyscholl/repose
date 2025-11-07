# frozen_string_literal: true

module Repose
  class AIGenerator
    def initialize
      # Note: OpenAI dependency temporarily removed for compatibility
      # @client = OpenAI::Client.new(access_token: Repose.config.openai_api_key)
    end

    def generate(context)
      {
        name: context[:name],
        description: generate_description(context),
        topics: generate_topics(context),
        readme: generate_readme(context)
      }
    end

    private

    def generate_description(context)
      # Fallback description generation without AI for now
      base_desc = "A #{context[:language]}"
      base_desc += " #{context[:framework]}" if context[:framework]
      base_desc += " project"
      base_desc += " for #{context[:purpose]}" if context[:purpose] && !context[:purpose].empty?
      
      base_desc.capitalize
    end

    def generate_topics(context)
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

    def generate_readme(context)
      generate_fallback_readme(context)
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