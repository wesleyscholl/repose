# frozen_string_literal: true

RSpec.describe "Integration Tests", type: :integration do
  let(:config_file_path) { File.expand_path("~/.repose_integration_test.yml") }
  
  before do
    # Clean up any existing test config
    File.delete(config_file_path) if File.exist?(config_file_path)
  end
  
  after do
    File.delete(config_file_path) if File.exist?(config_file_path)
  end

  describe "End-to-end repository creation workflow" do
    let(:mock_github_client) { instance_double(Repose::GitHubClient) }
    let(:mock_ai_generator) { instance_double(Repose::AIGenerator) }
    let(:test_config) { Repose::Config.new }
    
    let(:ai_content) do
      {
        name: "integration-test-repo",
        description: "A Ruby CLI project for testing integration",
        topics: ["ruby", "cli", "test"],
        readme: "# Integration Test Repo\n\nThis is a test repository."
      }
    end
    
    let(:github_repo) do
      OpenStruct.new(
        full_name: "testuser/integration-test-repo",
        html_url: "https://github.com/testuser/integration-test-repo",
        default_branch: "main"
      )
    end

    before do
      # Override config file path for testing
      allow(test_config).to receive(:config_file_path).and_return(config_file_path)
      allow(Repose).to receive(:config).and_return(test_config)
      
      # Mock external services
      allow(Repose::GitHubClient).to receive(:new).and_return(mock_github_client)
      allow(Repose::AIGenerator).to receive(:new).and_return(mock_ai_generator)
      
      # Set up mocked responses
      allow(mock_ai_generator).to receive(:generate).and_return(ai_content)
      allow(mock_github_client).to receive(:create_repository).and_return(github_repo)
      
      # Set up valid configuration
      test_config.github_token = "test_github_token"
      test_config.openai_api_key = "test_openai_key"
    end

    it "successfully creates a repository from start to finish" do
      # Verify AI content generation is called with correct context
      expect(mock_ai_generator).to receive(:generate).with(
        hash_including(
          name: "integration-test-repo",
          language: "ruby"
        )
      ).and_return(ai_content)

      # Verify GitHub repository creation
      expect(mock_github_client).to receive(:create_repository).with(
        name: "integration-test-repo",
        description: "A Ruby CLI project for testing integration",
        private: false,
        topics: ["ruby", "cli", "test"],
        readme: "# Integration Test Repo\n\nThis is a test repository."
      ).and_return(github_repo)

      # Execute the workflow
      cli = Repose::CLI.new
      cli.options = {
        "language" => "ruby",
        "dry_run" => false
      }
      
      # Mock user interactions
      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(prompt).to receive(:select).with("Framework/Library (optional):", anything).and_return("None")
      allow(prompt).to receive(:ask).with("What will this project do? (optional):").and_return("testing integration")
      allow(prompt).to receive(:yes?).with("Create repository?").and_return(true)
      
      # Mock spinner
      spinner = instance_double(TTY::Spinner)
      allow(TTY::Spinner).to receive(:new).and_return(spinner)
      allow(spinner).to receive(:auto_spin)
      allow(spinner).to receive(:success)
      
      # Silence output
      allow($stdout).to receive(:puts)
      
      # Execute
      cli.create("integration-test-repo")
    end
  end

  describe "Configuration workflow" do
    let(:test_config) { Repose::Config.new }
    
    before do
      allow(test_config).to receive(:config_file_path).and_return(config_file_path)
      allow(Repose).to receive(:config).and_return(test_config)
    end

    it "successfully saves and loads configuration" do
      # Set up configuration
      test_config.github_token = "gh_test_token"
      test_config.openai_api_key = "sk_test_key"
      test_config.default_topics = ["ruby", "testing"]
      test_config.default_language = "ruby"
      
      # Save configuration
      test_config.save!
      
      # Verify file was created with correct permissions
      expect(File.exist?(config_file_path)).to be true
      file_stat = File.stat(config_file_path)
      expect(file_stat.mode & 0o777).to eq(0o600)
      
      # Create new config instance and verify it loads the saved data
      new_config = Repose::Config.new
      allow(new_config).to receive(:config_file_path).and_return(config_file_path)
      new_config.load_config
      
      expect(new_config.github_token).to eq("gh_test_token")
      expect(new_config.openai_api_key).to eq("sk_test_key")
      expect(new_config.default_topics).to eq(["ruby", "testing"])
      expect(new_config.default_language).to eq("ruby")
      expect(new_config.valid?).to be true
    end

    it "handles configuration via CLI" do
      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      
      allow(prompt).to receive(:mask).with("GitHub Personal Access Token:").and_return("new_gh_token")
      allow(prompt).to receive(:mask).with("OpenAI API Key:").and_return("new_openai_key")
      allow(prompt).to receive(:ask).with("Default topics (comma-separated):").and_return("go,api,microservice")
      
      # Silence output
      allow($stdout).to receive(:puts)
      
      cli = Repose::CLI.new
      cli.configure
      
      expect(test_config.github_token).to eq("new_gh_token")
      expect(test_config.openai_api_key).to eq("new_openai_key")
      expect(test_config.default_topics).to eq(["go", "api", "microservice"])
    end
  end

  describe "Error handling integration" do
    let(:test_config) { Repose::Config.new }
    
    before do
      allow(Repose).to receive(:config).and_return(test_config)
      test_config.github_token = "test_token"
      test_config.openai_api_key = "test_key"
    end

    it "handles GitHub API errors gracefully" do
      mock_github_client = instance_double(Repose::GitHubClient)
      mock_ai_generator = instance_double(Repose::AIGenerator)
      
      allow(Repose::GitHubClient).to receive(:new).and_return(mock_github_client)
      allow(Repose::AIGenerator).to receive(:new).and_return(mock_ai_generator)
      
      allow(mock_ai_generator).to receive(:generate).and_return({
        name: "test-repo",
        description: "Test",
        topics: ["test"],
        readme: "# Test"
      })
      
      allow(mock_github_client).to receive(:create_repository)
        .and_raise(Repose::Errors::GitHubError.new("Repository already exists"))
      
      # Mock user interactions
      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(prompt).to receive(:select).and_return("ruby", "None")
      allow(prompt).to receive(:ask).and_return("")
      allow(prompt).to receive(:yes?).and_return(true)
      
      # Mock spinner
      spinner = instance_double(TTY::Spinner)
      allow(TTY::Spinner).to receive(:new).and_return(spinner)
      allow(spinner).to receive(:auto_spin)
      allow(spinner).to receive(:error)
      
      # Silence output
      allow($stdout).to receive(:puts)
      allow($stderr).to receive(:puts)
      
      cli = Repose::CLI.new
      cli.options = { "dry_run" => false }
      
      expect { cli.create("test-repo") }.to raise_error(SystemExit)
      expect(spinner).to have_received(:error)
    end

    it "handles AI generation errors gracefully" do
      mock_ai_generator = instance_double(Repose::AIGenerator)
      allow(Repose::AIGenerator).to receive(:new).and_return(mock_ai_generator)
      allow(mock_ai_generator).to receive(:generate)
        .and_raise(StandardError.new("AI service unavailable"))
      
      # Mock user interactions
      prompt = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(prompt).to receive(:select).and_return("python", "None")
      allow(prompt).to receive(:ask).and_return("")
      
      # Mock spinner
      spinner = instance_double(TTY::Spinner)
      allow(TTY::Spinner).to receive(:new).and_return(spinner)
      allow(spinner).to receive(:auto_spin)
      allow(spinner).to receive(:error)
      
      # Silence output
      allow($stdout).to receive(:puts)
      allow($stderr).to receive(:puts)
      
      cli = Repose::CLI.new
      cli.options = { "dry_run" => false }
      
      expect { cli.create("test-repo") }.to raise_error(SystemExit)
      expect(spinner).to have_received(:error)
    end
  end

  describe "Module-level functionality" do
    it "provides global configuration access" do
      expect(Repose.config).to be_a(Repose::Config)
    end

    it "allows configuration via block" do
      Repose.configure do |config|
        config.github_token = "block_token"
        config.default_language = "rust"
      end
      
      expect(Repose.config.github_token).to eq("block_token")
      expect(Repose.config.default_language).to eq("rust")
    end
  end
end