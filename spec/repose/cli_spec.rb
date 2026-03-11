# frozen_string_literal: true

RSpec.describe Repose::CLI do
  let(:cli) { described_class.new }
  let(:config) { instance_double(Repose::Config, github_token: "token", openai_api_key: "key") }
  let(:ai_generator) { instance_double(Repose::AIGenerator) }
  let(:github_client) { instance_double(Repose::GitHubClient) }
  let(:prompt) { instance_double(TTY::Prompt) }
  let(:spinner) { instance_double(TTY::Spinner) }

  # Default: user has no org memberships — select_namespace returns nil without prompting
  let(:personal_namespaces) { [{ name: "testuser (personal)", value: "testuser" }] }

  before do
    allow(Repose).to receive(:config).and_return(config)
    allow(Repose::AIGenerator).to receive(:new).and_return(ai_generator)
    allow(Repose::GitHubClient).to receive(:new).and_return(github_client)
    allow(github_client).to receive(:available_namespaces).and_return(personal_namespaces)
    allow(TTY::Prompt).to receive(:new).and_return(prompt)
    allow(TTY::Spinner).to receive(:new).and_return(spinner)
    allow(spinner).to receive(:auto_spin)
    allow(spinner).to receive(:success)
    allow(spinner).to receive(:error)

    # Silence output during tests
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:puts)
  end

  describe "#version" do
    it "outputs the version" do
      expect { cli.version }.to output(/Repose v#{Repose::VERSION}/o).to_stdout
    end
  end

  describe "#configure" do
    before do
      allow(prompt).to receive(:mask).with("GitHub Personal Access Token:").and_return("new_github_token")
      allow(prompt).to receive(:mask).with("OpenAI API Key:").and_return("new_openai_key")
      allow(prompt).to receive(:ask).with("Default topics (comma-separated):").and_return("ruby,cli,tool")
      allow(config).to receive(:github_token=)
      allow(config).to receive(:openai_api_key=)
      allow(config).to receive(:default_topics=)
      allow(config).to receive(:save!)
    end

    it "prompts for GitHub token and saves it" do
      cli.configure

      expect(prompt).to have_received(:mask).with("GitHub Personal Access Token:")
      expect(config).to have_received(:github_token=).with("new_github_token")
    end

    it "prompts for OpenAI key and saves it" do
      cli.configure

      expect(prompt).to have_received(:mask).with("OpenAI API Key:")
      expect(config).to have_received(:openai_api_key=).with("new_openai_key")
    end

    it "prompts for default topics and saves them" do
      cli.configure

      expect(prompt).to have_received(:ask).with("Default topics (comma-separated):")
      expect(config).to have_received(:default_topics=).with(%w[ruby cli tool])
    end

    it "saves the configuration" do
      cli.configure
      expect(config).to have_received(:save!)
    end

    context "when user provides empty responses" do
      before do
        allow(prompt).to receive_messages(mask: "", ask: "")
      end

      it "does not update config values" do
        cli.configure

        expect(config).not_to have_received(:github_token=)
        expect(config).not_to have_received(:openai_api_key=)
        expect(config).not_to have_received(:default_topics=)
      end
    end
  end

  describe "#create" do
    let(:ai_content) do
      {
        name: "test-repo",
        description: "A test repository",
        topics: %w[ruby test],
        readme: "# Test Repo\n\nThis is a test repository.",
        language: "ruby",
        framework: nil,
        license: "mit"
      }
    end

    let(:repo_result) do
      OpenStruct.new(
        full_name: "testuser/test-repo",
        html_url: "https://github.com/testuser/test-repo"
      )
    end

    before do
      allow(ai_generator).to receive(:generate).and_return(ai_content)
      allow(github_client).to receive(:create_repository).and_return(repo_result)
      allow(github_client).to receive(:create_file)
    end

    # Use symbol keys so options[:key] resolves correctly (Thor does not
    # auto-convert to HashWithIndifferentAccess when options= is set directly)
    context "when repository name is provided as argument" do
      let(:options) { { language: "ruby", dry_run: false } }

      before do
        allow(prompt).to receive(:select).with("Framework/Library (optional):", anything).and_return("None")
        allow(prompt).to receive(:select).with("Choose a license:", anything).and_return("mit")
        allow(prompt).to receive(:ask).with("What will this project do? (optional):").and_return("A test project")
        allow(prompt).to receive(:yes?).with("Create repository?").and_return(true)
      end

      it "uses the provided name" do
        cli.options = options
        cli.create("test-repo")

        expect(ai_generator).to have_received(:generate).with(
          hash_including(name: "test-repo")
        )
      end

      it "generates AI content" do
        cli.options = options
        cli.create("test-repo")

        expect(ai_generator).to have_received(:generate)
      end

      it "creates the repository" do
        cli.options = options
        cli.create("test-repo")

        expect(github_client).to have_received(:create_repository)
      end

      it "passes nil owner when user only has personal account" do
        cli.options = options
        cli.create("test-repo")

        expect(github_client).to have_received(:create_repository).with(
          hash_including(owner: nil)
        )
      end
    end

    context "when repository name is not provided" do
      let(:options) { { dry_run: false } }

      before do
        allow(prompt).to receive(:ask).with("Repository name:", anything).and_return("prompted-repo")
        allow(prompt).to receive(:select).and_return("ruby", "None", "mit")
        allow(prompt).to receive(:ask).with("What will this project do? (optional):").and_return("")
        allow(prompt).to receive(:yes?).and_return(true)
      end

      it "prompts for repository name" do
        cli.options = options
        cli.create

        expect(prompt).to have_received(:ask).with("Repository name:", anything)
      end
    end

    context "when language is provided in options" do
      let(:options) { { language: "python", dry_run: false } }

      before do
        allow(prompt).to receive(:select).with("Framework/Library (optional):", anything).and_return("None")
        allow(prompt).to receive(:select).with("Choose a license:", anything).and_return("mit")
        allow(prompt).to receive_messages(ask: "", yes?: true)
      end

      it "does not prompt for language" do
        cli.options = options
        cli.create("test-repo")

        expect(prompt).not_to have_received(:select).with("Primary programming language:", anything, anything)
      end

      it "uses provided language" do
        cli.options = options
        cli.create("test-repo")

        expect(ai_generator).to have_received(:generate).with(
          hash_including(language: "python")
        )
      end
    end

    context "when framework is provided in options" do
      let(:options) { { language: "ruby", framework: "rails", dry_run: false } }

      before do
        allow(prompt).to receive(:select).with("Choose a license:", anything).and_return("mit")
        allow(prompt).to receive_messages(ask: "", yes?: true)
      end

      it "does not prompt for framework" do
        cli.options = options
        cli.create("test-repo")

        expect(prompt).not_to have_received(:select).with("Framework/Library (optional):", anything)
      end

      it "uses provided framework" do
        cli.options = options
        cli.create("test-repo")

        expect(ai_generator).to have_received(:generate).with(
          hash_including(framework: "rails")
        )
      end
    end

    context "when --org option is specified" do
      let(:options) { { language: "ruby", org: "my-org", dry_run: false } }

      before do
        allow(prompt).to receive(:select).with("Framework/Library (optional):", anything).and_return("None")
        allow(prompt).to receive(:select).with("Choose a license:", anything).and_return("mit")
        allow(prompt).to receive_messages(ask: "", yes?: true)
      end

      it "does not prompt for namespace" do
        cli.options = options
        cli.create("test-repo")

        expect(prompt).not_to have_received(:select).with("Create repository under:", anything)
      end

      it "passes the specified org as owner to create_repository" do
        cli.options = options
        cli.create("test-repo")

        expect(github_client).to have_received(:create_repository).with(
          hash_including(owner: "my-org")
        )
      end
    end

    context "when user has multiple namespaces (orgs)" do
      let(:multi_namespaces) do
        [
          { name: "testuser (personal)", value: "testuser" },
          { name: "my-org", value: "my-org" }
        ]
      end
      let(:options) { { language: "ruby", dry_run: false } }

      before do
        allow(github_client).to receive(:available_namespaces).and_return(multi_namespaces)
        allow(prompt).to receive(:select).with("Create repository under:", multi_namespaces).and_return("my-org")
        allow(prompt).to receive(:select).with("Framework/Library (optional):", anything).and_return("None")
        allow(prompt).to receive(:select).with("Choose a license:", anything).and_return("mit")
        allow(prompt).to receive_messages(ask: "", yes?: true)
      end

      it "prompts for namespace selection" do
        cli.options = options
        cli.create("test-repo")

        expect(prompt).to have_received(:select).with("Create repository under:", multi_namespaces)
      end

      it "passes the selected org as owner" do
        cli.options = options
        cli.create("test-repo")

        expect(github_client).to have_received(:create_repository).with(
          hash_including(owner: "my-org")
        )
      end

      context "when user selects the personal account" do
        before do
          allow(prompt).to receive(:select).with("Create repository under:", multi_namespaces).and_return("testuser")
        end

        it "passes nil as owner" do
          cli.options = options
          cli.create("test-repo")

          expect(github_client).to have_received(:create_repository).with(
            hash_including(owner: nil)
          )
        end
      end
    end

    context "when namespace fetching fails" do
      let(:options) { { language: "ruby", dry_run: false } }

      before do
        allow(github_client).to receive(:available_namespaces)
          .and_raise(Repose::Errors::GitHubError.new("API error"))
        allow(prompt).to receive(:select).with("Framework/Library (optional):", anything).and_return("None")
        allow(prompt).to receive(:select).with("Choose a license:", anything).and_return("mit")
        allow(prompt).to receive_messages(ask: "", yes?: true)
      end

      it "falls back to personal account (nil owner) and continues" do
        cli.options = options
        cli.create("test-repo")

        expect(github_client).to have_received(:create_repository).with(
          hash_including(owner: nil)
        )
      end
    end

    context "when dry_run option is true" do
      let(:options) { { language: "ruby", dry_run: true } }

      before do
        allow(prompt).to receive(:select).and_return("None", "mit")
        allow(prompt).to receive(:ask).and_return("")
        allow(prompt).to receive(:yes?)
      end

      it "does not prompt for confirmation" do
        cli.options = options
        cli.create("test-repo")

        expect(prompt).not_to have_received(:yes?)
      end

      it "does not create repository" do
        cli.options = options
        cli.create("test-repo")

        expect(github_client).not_to have_received(:create_repository)
      end
    end

    context "when user declines to create repository" do
      let(:options) { { language: "ruby", dry_run: false } }

      before do
        allow(prompt).to receive(:select).and_return("None", "mit")
        allow(prompt).to receive_messages(ask: "", yes?: false)
      end

      it "does not create repository" do
        cli.options = options
        cli.create("test-repo")

        expect(github_client).not_to have_received(:create_repository)
      end
    end

    context "when AI generation fails" do
      before do
        allow(prompt).to receive(:select).and_return("ruby", "None", "mit")
        allow(prompt).to receive(:ask).and_return("")
        allow(ai_generator).to receive(:generate).and_raise(StandardError.new("AI failed"))
      end

      it "handles the error gracefully" do
        cli.options = { dry_run: false }

        expect { cli.create("test-repo") }.to raise_error(SystemExit)
        expect(spinner).to have_received(:error)
      end
    end

    context "when repository creation fails" do
      before do
        allow(prompt).to receive(:select).and_return("ruby", "None", "mit")
        allow(prompt).to receive_messages(ask: "", yes?: true)
        allow(github_client).to receive(:create_repository)
          .and_raise(Repose::Errors::GitHubError.new("Failed to create repo"))
      end

      it "handles the error gracefully" do
        cli.options = { dry_run: false }

        expect { cli.create("test-repo") }.to raise_error(SystemExit)
        expect(spinner).to have_received(:error)
      end
    end
  end

  describe "private methods" do
    describe "#gather_context" do
      let(:options) { {} }

      before do
        allow(prompt).to receive(:select).with("Primary programming language:", anything, anything).and_return("go")
        allow(prompt).to receive(:select).with("Framework/Library (optional):", anything).and_return("Gin")
        allow(prompt).to receive(:select).with("Choose a license:", anything).and_return("mit")
        allow(prompt).to receive(:ask).with("What will this project do? (optional):").and_return("API server")
      end

      it "gathers context from user input" do
        context = cli.send(:gather_context, "api-server", options, prompt)

        expect(context[:name]).to eq("api-server")
        expect(context[:language]).to eq("go")
        expect(context[:framework]).to eq("Gin")
        expect(context[:purpose]).to eq("API server")
      end
    end

    describe "#framework_suggestions" do
      it "returns ruby frameworks for ruby" do
        suggestions = cli.send(:framework_suggestions, "ruby")
        expect(suggestions).to include("Rails", "Sinatra")
      end

      it "returns javascript frameworks for javascript" do
        suggestions = cli.send(:framework_suggestions, "javascript")
        expect(suggestions).to include("React", "Vue", "Express")
      end

      it "returns empty array for unknown language" do
        suggestions = cli.send(:framework_suggestions, "unknown")
        expect(suggestions).to eq([])
      end
    end

    describe "#select_namespace" do
      # Pastel uses method_missing for color methods, so use a plain double
      let(:pastel) { double("pastel") }

      before do
        allow(pastel).to receive(:yellow).and_return("warning")
      end

      context "when user has no orgs (single namespace)" do
        before do
          allow(github_client).to receive(:available_namespaces)
            .and_return([{ name: "testuser (personal)", value: "testuser" }])
          allow(prompt).to receive(:select)
        end

        it "returns nil without prompting" do
          result = cli.send(:select_namespace, prompt, pastel)
          expect(result).to be_nil
          expect(prompt).not_to have_received(:select).with("Create repository under:", anything)
        end
      end

      context "when user has orgs" do
        let(:namespaces) do
          [
            { name: "testuser (personal)", value: "testuser" },
            { name: "my-org", value: "my-org" }
          ]
        end

        before do
          allow(github_client).to receive(:available_namespaces).and_return(namespaces)
        end

        it "prompts user to select a namespace" do
          allow(prompt).to receive(:select).with("Create repository under:", namespaces).and_return("my-org")
          cli.send(:select_namespace, prompt, pastel)
          expect(prompt).to have_received(:select).with("Create repository under:", namespaces)
        end

        it "returns the selected org login" do
          allow(prompt).to receive(:select).with("Create repository under:", namespaces).and_return("my-org")
          result = cli.send(:select_namespace, prompt, pastel)
          expect(result).to eq("my-org")
        end

        it "returns nil when user selects their personal account" do
          allow(prompt).to receive(:select).with("Create repository under:", namespaces).and_return("testuser")
          result = cli.send(:select_namespace, prompt, pastel)
          expect(result).to be_nil
        end
      end

      context "when fetching namespaces raises an error" do
        before do
          allow(github_client).to receive(:available_namespaces)
            .and_raise(Repose::Errors::AuthenticationError.new("bad token"))
        end

        it "returns nil (falls back to personal account)" do
          result = cli.send(:select_namespace, prompt, pastel)
          expect(result).to be_nil
        end
      end
    end
  end
end
