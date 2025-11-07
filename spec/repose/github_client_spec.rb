# frozen_string_literal: true

RSpec.describe Repose::GitHubClient do
  let(:config) { instance_double(Repose::Config, github_token: "gh_token_123") }
  let(:client) { described_class.new }
  let(:octokit_client) { instance_double(Octokit::Client) }

  before do
    allow(Repose).to receive(:config).and_return(config)
    allow(Octokit::Client).to receive(:new).with(access_token: "gh_token_123").and_return(octokit_client)
  end

  describe "#initialize" do
    it "creates an Octokit client with the configured token" do
      expect(Octokit::Client).to have_received(:new).with(access_token: "gh_token_123")
    end
  end

  describe "#create_repository" do
    let(:repo_data) do
      OpenStruct.new(
        full_name: "user/test-repo",
        html_url: "https://github.com/user/test-repo",
        default_branch: "main"
      )
    end

    let(:create_params) do
      {
        name: "test-repo",
        description: "A test repository",
        private: false,
        topics: ["ruby", "cli"],
        readme: "# Test Repo\n\nThis is a test."
      }
    end

    context "when repository creation succeeds" do
      before do
        allow(octokit_client).to receive(:create_repository).and_return(repo_data)
        allow(octokit_client).to receive(:replace_all_topics)
        allow(octokit_client).to receive(:create_contents)
      end

      it "creates repository with correct parameters" do
        client.create_repository(**create_params)

        expect(octokit_client).to have_received(:create_repository).with(
          "test-repo",
          {
            description: "A test repository",
            private: false,
            auto_init: false
          }
        )
      end

      it "adds topics to the repository" do
        client.create_repository(**create_params)

        expect(octokit_client).to have_received(:replace_all_topics).with(
          "user/test-repo",
          ["ruby", "cli"]
        )
      end

      it "creates README file" do
        client.create_repository(**create_params)

        expect(octokit_client).to have_received(:create_contents).with(
          "user/test-repo",
          "README.md",
          "Initial README",
          "# Test Repo\n\nThis is a test.",
          branch: "main"
        )
      end

      it "returns the created repository" do
        result = client.create_repository(**create_params)
        expect(result).to eq(repo_data)
      end

      context "when no topics are provided" do
        let(:create_params_no_topics) do
          create_params.merge(topics: [])
        end

        it "does not call replace_all_topics" do
          client.create_repository(**create_params_no_topics)
          expect(octokit_client).not_to have_received(:replace_all_topics)
        end
      end

      context "when no README is provided" do
        let(:create_params_no_readme) do
          create_params.merge(readme: nil)
        end

        it "does not create README file" do
          client.create_repository(**create_params_no_readme)
          expect(octokit_client).not_to have_received(:create_contents)
        end
      end

      context "when creating private repository" do
        let(:private_params) do
          create_params.merge(private: true)
        end

        it "sets private flag to true" do
          client.create_repository(**private_params)

          expect(octokit_client).to have_received(:create_repository).with(
            "test-repo",
            {
              description: "A test repository",
              private: true,
              auto_init: false
            }
          )
        end
      end
    end

    context "when GitHub API returns an error" do
      before do
        allow(octokit_client).to receive(:create_repository)
          .and_raise(Octokit::UnprocessableEntity.new)
      end

      it "raises a GitHubError" do
        expect {
          client.create_repository(**create_params)
        }.to raise_error(Repose::Errors::GitHubError, /GitHub API error/)
      end
    end
  end

  describe "#repository_exists?" do
    let(:user) { OpenStruct.new(login: "testuser") }

    before do
      allow(octokit_client).to receive(:user).and_return(user)
    end

    context "when repository exists" do
      before do
        allow(octokit_client).to receive(:repository?).with("testuser/existing-repo").and_return(true)
      end

      it "returns true" do
        expect(client.repository_exists?("existing-repo")).to be true
      end
    end

    context "when repository does not exist" do
      before do
        allow(octokit_client).to receive(:repository?).with("testuser/non-existing-repo").and_return(false)
      end

      it "returns false" do
        expect(client.repository_exists?("non-existing-repo")).to be false
      end
    end

    context "when repository is not found (raises NotFound)" do
      before do
        allow(octokit_client).to receive(:repository?).with("testuser/not-found-repo")
          .and_raise(Octokit::NotFound.new)
      end

      it "returns false" do
        expect(client.repository_exists?("not-found-repo")).to be false
      end
    end
  end

  describe "#user_info" do
    let(:user_data) do
      OpenStruct.new(
        login: "testuser",
        name: "Test User",
        email: "test@example.com"
      )
    end

    context "when API call succeeds" do
      before do
        allow(octokit_client).to receive(:user).and_return(user_data)
      end

      it "returns user information" do
        result = client.user_info
        expect(result).to eq(user_data)
        expect(octokit_client).to have_received(:user)
      end
    end

    context "when API call fails" do
      before do
        allow(octokit_client).to receive(:user).and_raise(Octokit::Unauthorized.new)
      end

      it "raises a GitHubError" do
        expect {
          client.user_info
        }.to raise_error(Repose::Errors::GitHubError, /Failed to fetch user info/)
      end
    end
  end
end