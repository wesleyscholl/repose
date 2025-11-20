# frozen_string_literal: true

require "thor"
require "pastel"
require "tty-prompt"
require "tty-spinner"

module Repose
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "create [NAME]", "Create a new repository with AI assistance"
    long_desc <<~DESC
      Create a new GitHub repository with AI-generated description, topics,
      and README. The AI will analyze the repository name and any additional
      context you provide to generate appropriate content.

      Examples:
        $ repose create my-awesome-project
        $ repose create web-scraper --language ruby --framework rails
    DESC
    option :language, type: :string, desc: "Primary programming language"
    option :framework, type: :string, desc: "Framework or library to use"
    option :description, type: :string, desc: "Custom description override"
    option :private, type: :boolean, default: false, desc: "Create private repository"
    option :template, type: :string, desc: "Repository template to use"
    option :topics, type: :array, desc: "Custom topics/tags"
    option :dry_run, type: :boolean, default: false, desc: "Preview without creating"
    def create(name = nil)
      pastel = Pastel.new
      prompt = TTY::Prompt.new

      puts pastel.cyan("🎯 Repose - AI Repository Creator")
      puts pastel.dim("=" * 40)

      # Get repository name
      name ||= prompt.ask("Repository name:", required: true) do |q|
        q.validate(/\A[a-zA-Z0-9._-]+\z/, "Invalid repository name format")
      end

      # Gather context
      context = gather_context(name, options, prompt)
      
      # Generate AI content
      spinner = TTY::Spinner.new("[:spinner] Generating repository content with AI...", format: :dots)
      spinner.auto_spin

      begin
        ai_content = AIGenerator.new.generate(context)
        spinner.success("✅")
      rescue => e
        spinner.error("❌")
        puts pastel.red("Error generating AI content: #{e.message}")
        exit 1
      end

      # Display preview
      display_preview(ai_content, pastel)

      # Confirm creation
      unless options[:dry_run]
        if prompt.yes?("Create repository?")
          create_repository(name, ai_content, options, pastel)
        else
          puts pastel.yellow("Repository creation cancelled.")
        end
      end
    end

    desc "configure", "Configure Repose settings"
    def configure
      prompt = TTY::Prompt.new
      config = Repose.config

      puts "🔧 Configuring Repose..."

      github_token = prompt.mask("GitHub Personal Access Token:")
      config.github_token = github_token unless github_token.empty?

      openai_key = prompt.mask("OpenAI API Key:")
      config.openai_api_key = openai_key unless openai_key.empty?

      default_topics = prompt.ask("Default topics (comma-separated):")
      config.default_topics = default_topics.split(",").map(&:strip) unless default_topics.empty?

      config.save!
      puts "✅ Configuration saved!"
    end

    desc "version", "Display version information"
    def version
      puts "Repose v#{Repose::VERSION}"
    end

    private

    def gather_context(name, options, prompt)
      context = {
        name: name,
        language: options[:language],
        framework: options[:framework],
        description: options[:description],
        topics: options[:topics] || []
      }

      # Interactive prompts for missing context
      unless context[:language]
        languages = %w[c c++ c# go java javascript kotlin mojo php python ruby rust scala typescript]
        context[:language] = prompt.select("Primary programming language:", languages, per_page: 14)
      end

      unless context[:framework]
        frameworks = framework_suggestions(context[:language])
        if frameworks.any?
          context[:framework] = prompt.select("Framework/Library (optional):", ["None"] + frameworks)
          context[:framework] = nil if context[:framework] == "None"
        end
      end

      # Additional context
      context[:purpose] = prompt.ask("What will this project do? (optional):")
      
      context
    end

    def framework_suggestions(language)
      frameworks = {
        "ruby" => ["Rails", "Sinatra", "Hanami", "Roda"],
        "javascript" => ["React", "Vue", "Express", "Next.js", "Nuxt"],
        "typescript" => ["React", "Vue", "Express", "Next.js", "Nuxt", "Angular"],
        "python" => ["Django", "Flask", "FastAPI", "Streamlit"],
        "java" => ["Spring Boot", "Quarkus", "Micronaut"],
        "go" => ["Gin", "Echo", "Fiber", "Chi"],
        "rust" => ["Actix", "Axum", "Warp", "Rocket"],
        "swift" => ["Vapor", "Perfect", "Kitura"]
      }

      frameworks[language] || []
    end

    def display_preview(content, pastel)
      puts "\n" + pastel.cyan("📋 Generated Repository Content")
      puts pastel.dim("-" * 40)
      
      puts pastel.bold("Name: ") + content[:name]
      puts pastel.bold("Description: ") + content[:description]
      puts pastel.bold("Topics: ") + content[:topics].join(", ")
      
      puts "\n" + pastel.bold("README Preview:")
      puts pastel.dim(content[:readme][0..300] + "...")
      puts
    end

    def create_repository(name, content, options, pastel)
      spinner = TTY::Spinner.new("[:spinner] Creating GitHub repository...", format: :dots)
      spinner.auto_spin

      begin
        github_client = GitHubClient.new
        repo = github_client.create_repository(
          name: name,
          description: content[:description],
          private: options[:private],
          topics: content[:topics],
          readme: content[:readme]
        )
        
        spinner.success("✅")
        puts pastel.green("Repository created successfully!")
        puts pastel.cyan("🔗 #{repo.html_url}")
      rescue => e
        spinner.error("❌")
        puts pastel.red("Error creating repository: #{e.message}")
        exit 1
      end
    end
  end
end