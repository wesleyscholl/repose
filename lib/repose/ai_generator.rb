# frozen_string_literal: true

require "openai"

module Repose
  class AIGenerator
    def initialize
      @client = OpenAI::Client.new(access_token: Repose.config.openai_api_key)
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
      prompt = build_description_prompt(context)
      
      response = @client.chat(
        parameters: {
          model: "gpt-4",
          messages: [{ role: "user", content: prompt }],
          max_tokens: 100,
          temperature: 0.7
        }
      )

      response.dig("choices", 0, "message", "content")&.strip
    rescue => e
      raise Errors::AIError, "Failed to generate description: #{e.message}"
    end

    def generate_topics(context)
      prompt = build_topics_prompt(context)
      
      response = @client.chat(
        parameters: {
          model: "gpt-4",
          messages: [{ role: "user", content: prompt }],
          max_tokens: 150,
          temperature: 0.5
        }
      )

      content = response.dig("choices", 0, "message", "content")&.strip
      parse_topics(content)
    rescue => e
      # Fallback to basic topics
      basic_topics = [context[:language], context[:framework]].compact.map(&:downcase)
      basic_topics.empty? ? ["project"] : basic_topics
    end

    def generate_readme(context)
      prompt = build_readme_prompt(context)
      
      response = @client.chat(
        parameters: {
          model: "gpt-4",
          messages: [{ role: "user", content: prompt }],
          max_tokens: 1500,
          temperature: 0.6
        }
      )

      response.dig("choices", 0, "message", "content")&.strip
    rescue => e
      generate_fallback_readme(context)
    end

    def build_description_prompt(context)
      <<~PROMPT
        Create a concise, professional GitHub repository description (under 100 characters) for:

        Repository name: #{context[:name]}
        Language: #{context[:language]}
        Framework: #{context[:framework]}
        Purpose: #{context[:purpose]}

        The description should be:
        - Clear and specific
        - Professional but engaging
        - Under 100 characters
        - No redundant words

        Just return the description, no quotes or extra text.
      PROMPT
    end

    def build_topics_prompt(context)
      <<~PROMPT
        Generate 5-8 relevant GitHub topics/tags for this repository:

        Repository name: #{context[:name]}
        Language: #{context[:language]}
        Framework: #{context[:framework]}
        Purpose: #{context[:purpose]}

        Return only lowercase, hyphenated topics separated by commas.
        Include language, framework, and relevant domain tags.
        
        Example format: ruby, rails, api, web-development, json
      PROMPT
    end

    def build_readme_prompt(context)
      <<~PROMPT
        Create a professional README.md for this repository:

        Repository name: #{context[:name]}
        Language: #{context[:language]}
        Framework: #{context[:framework]}
        Purpose: #{context[:purpose]}

        Include these sections:
        - Project title and brief description
        - Features (2-4 key features)
        - Installation instructions
        - Usage example
        - Contributing guidelines
        - License section

        Use proper Markdown formatting. Be specific to the language/framework.
        Keep it professional but approachable.
      PROMPT
    end

    def parse_topics(content)
      return [] unless content
      
      # Extract topics from various formats
      topics = content.split(/[,\n]/)
                     .map(&:strip)
                     .map { |topic| topic.gsub(/[^a-z0-9-]/, "") }
                     .reject(&:empty?)
                     .uniq
                     .first(8)

      topics.empty? ? ["project"] : topics
    end

    def generate_fallback_readme(context)
      <<~README
        # #{context[:name].split(/[-_]/).map(&:capitalize).join(" ")}

        A #{context[:language]} #{context[:framework] ? "#{context[:framework]} " : ""}project.

        ## Installation

        ```bash
        git clone https://github.com/yourusername/#{context[:name]}.git
        cd #{context[:name]}
        ```

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
  end
end