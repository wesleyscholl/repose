# frozen_string_literal: true

RSpec.describe Repose::GitHubClient do
  let(:config) { instance_double(Repose::Config, github_token: "gh_token_123") }
  let(:client) { described_class.new }
  let(:octokit_client) { instance_double(Octokit::Client) }
  let(:user_data) { OpenStruct.new(login: "testuser", name: "Test User", email: "test@example.com") }

  before do
    allow(Repose).to receive(:config).and_return(config)
    allow(Octokit::Client).to receive(:new).with(access_token: "gh_token_123").and_return(octokit_client)
    allow(octokit_client).to receive(:auto_paginate=)
  end

  describe "#initialize" do
    it "creates an Octokit client with the configured token" do
      client # trigger lazy let instantiation
      expect(Octokit::Client).to have_received(:new).with(access_token: "gh_token_123")
    end

    context "when no token is configured" do
      let(:config) { instance_double(Repose::Config, github_token: nil) }

      before { allow(ENV).to receive(:fetch).with("REPOSE_TOKEN", nil).and_return(nil) }

      it "raises a ConfigurationError" do
        expect { described_class.new }.to raise_error(Repose::Errors::ConfigurationError)
      end
    end
  end

  describe "#available_namespaces" do
    let(:org1) { OpenStruct.new(login: "my-org") }
    let(:org2) { OpenStruct.new(login: "another-org") }

    before do
      allow(octokit_client).to receive(:user).and_return(user_data)
    end

    context "when user has no org memberships" do
      before { allow(octokit_client).to receive(:organizations).and_return([]) }

      it "returns only the personal account namespace" do
        result = client.available_namespaces
        expect(result).to eq([{ name: "testuser (personal)", value: "testuser" }])
      end
    end

    context "when user belongs to multiple orgs" do
      before { allow(octokit_client).to receive(:organizations).and_return([org1, org2]) }

      it "returns personal account first, then orgs" do
        result = client.available_namespaces
        expect(result.first).to eq({ name: "testuser (personal)", value: "testuser" })
        expect(result).to include({ name: "my-org", value: "my-org" })
        expect(result).to include({ name: "another-org", value: "another-org" })
      end

      it "returns all namespaces" do
        result = client.available_namespaces
        expect(result.size).to eq(3)
      end
    end

    context "when GitHub returns an authentication error" do
      before { allow(octokit_client).to receive(:user).and_raise(Octokit::Unauthorized.new) }

      it "raises an AuthenticationError" do
        expect { client.available_namespaces }.to raise_error(Repose::Errors::AuthenticationError)
      end
    end

    context "when GitHub returns a generic error" do
      before do
        allow(octokit_client).to receive(:user).and_return(user_data)
        allow(octokit_client).to receive(:organizations).and_raise(Octokit::Error.new)
      end

      it "raises a GitHubError" do
        expect do
          client.available_namespaces
        end.to raise_error(Repose::Errors::GitHubError, /Failed to fetch organizations/)
      end
    end
  end

  describe "#create_repository" do
    let(:repo_data) do
      OpenStruct.new(
        full_name: "testuser/test-repo",
        html_url: "https://github.com/testuser/test-repo",
        default_branch: "main"
      )
    end

    let(:create_params) do
      {
        name: "test-repo",
        description: "A test repository",
        private: false,
        topics: %w[ruby cli],
        readme: "# Test Repo\n\nThis is a test."
      }
    end

    context "when repository creation succeeds" do
      before do
        allow(octokit_client).to receive_messages(user: user_data, create_repository: repo_data)
        allow(octokit_client).to receive(:replace_all_topics)
        allow(octokit_client).to receive(:create_contents)
      end

      it "creates repository with correct parameters" do
        client.create_repository(**create_params)

        expect(octokit_client).to have_received(:create_repository).with(
          "test-repo",
          hash_including(
            description: "A test repository",
            private: false,
            auto_init: false,
            has_issues: true,
            has_wiki: true,
            has_projects: true
          )
        )
      end

      it "does not include organization key for a personal repo" do
        client.create_repository(**create_params)

        expect(octokit_client).to have_received(:create_repository).with(
          "test-repo",
          hash_excluding(:organization)
        )
      end

      it "adds topics to the repository" do
        client.create_repository(**create_params)

        expect(octokit_client).to have_received(:replace_all_topics).with(
          "testuser/test-repo", %w[ruby cli]
        )
      end

      it "creates README file" do
        client.create_repository(**create_params)

        expect(octokit_client).to have_received(:create_contents).with(
          "testuser/test-repo",
          "README.md",
          "Initial commit: Add README",
          "# Test Repo\n\nThis is a test.",
          branch: "main"
        )
      end

      it "returns the created repository" do
        result = client.create_repository(**create_params)
        expect(result).to eq(repo_data)
      end

      context "when no topics are provided" do
        it "does not call replace_all_topics" do
          client.create_repository(**create_params, topics: [])
          expect(octokit_client).not_to have_received(:replace_all_topics)
        end
      end

      context "when no README is provided" do
        it "does not create README file" do
          client.create_repository(**create_params, readme: nil)
          expect(octokit_client).not_to have_received(:create_contents)
        end
      end

      context "when creating a private repository" do
        it "sets private flag to true" do
          client.create_repository(**create_params, private: true)

          expect(octokit_client).to have_received(:create_repository).with(
            "test-repo", hash_including(private: true)
          )
        end
      end

      context "when owner is an organization" do
        let(:org_repo_data) do
          OpenStruct.new(
            full_name: "my-org/test-repo",
            html_url: "https://github.com/my-org/test-repo",
            default_branch: "main"
          )
        end

        before do
          allow(octokit_client).to receive(:create_repository).and_return(org_repo_data)
        end

        it "passes organization key to Octokit" do
          client.create_repository(**create_params, owner: "my-org")

          expect(octokit_client).to have_received(:create_repository).with(
            "test-repo", hash_including(organization: "my-org")
          )
        end

        it "returns the org repository" do
          result = client.create_repository(**create_params, owner: "my-org")
          expect(result.full_name).to eq("my-org/test-repo")
        end
      end

      context "when owner matches the authenticated user login" do
        it "does not pass organization key" do
          client.create_repository(**create_params, owner: "testuser")

          expect(octokit_client).to have_received(:create_repository).with(
            "test-repo", hash_excluding(:organization)
          )
        end
      end

      context "when a license is specified" do
        it "includes the normalized license template for GitHub-supported keys" do
          client.create_repository(**create_params, license: "mit")

          expect(octokit_client).to have_received(:create_repository).with(
            "test-repo", hash_including(license_template: "mit")
          )
        end

        it "normalizes apache-2.0 correctly" do
          client.create_repository(**create_params, license: "apache-2.0")

          expect(octokit_client).to have_received(:create_repository).with(
            "test-repo", hash_including(license_template: "apache-2.0")
          )
        end

        it "does not include license_template for non-GitHub-supported licenses" do
          %w[busl-1.1 elastic-2.0 sspl-1.0 eupl-1.2].each do |unsupported|
            octokit_client.instance_variable_set(:@received_messages, {}) if octokit_client.respond_to?(:received_messages)
            allow(octokit_client).to receive(:create_repository).and_return(repo_data)

            client.create_repository(**create_params, license: unsupported)

            expect(octokit_client).to have_received(:create_repository).with(
              "test-repo", hash_not_including(:license_template)
            ).at_least(:once)
          end
        end
      end
    end

    context "when GitHub API returns Octokit::UnprocessableEntity" do
      before do
        allow(octokit_client).to receive(:user).and_return(user_data)
        allow(octokit_client).to receive(:create_repository)
          .and_raise(Octokit::UnprocessableEntity.new)
      end

      it "raises a GitHubError with 'already exist' message" do
        expect do
          client.create_repository(**create_params)
        end.to raise_error(Repose::Errors::GitHubError, /Repository creation failed/)
      end
    end

    context "when GitHub API returns Octokit::Unauthorized" do
      before do
        allow(octokit_client).to receive(:user).and_return(user_data)
        allow(octokit_client).to receive(:create_repository)
          .and_raise(Octokit::Unauthorized.new)
      end

      it "raises an AuthenticationError" do
        expect do
          client.create_repository(**create_params)
        end.to raise_error(Repose::Errors::AuthenticationError)
      end
    end
  end

  describe "#repository_exists?" do
    before do
      allow(octokit_client).to receive(:user).and_return(user_data)
    end

    context "when repository exists under personal account" do
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

    context "when an explicit owner is provided" do
      before do
        allow(octokit_client).to receive(:repository?).with("my-org/org-repo").and_return(true)
      end

      it "checks under the specified owner" do
        expect(client.repository_exists?("org-repo", "my-org")).to be true
      end
    end
  end

  describe "#user_info" do
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

    context "when API call is unauthorized" do
      before do
        allow(octokit_client).to receive(:user).and_raise(Octokit::Unauthorized.new)
      end

      it "raises an AuthenticationError" do
        expect do
          client.user_info
        end.to raise_error(Repose::Errors::AuthenticationError, /Failed to authenticate/)
      end
    end

    context "when API call raises a generic error" do
      before do
        allow(octokit_client).to receive(:user).and_raise(Octokit::Error.new)
      end

      it "raises a GitHubError" do
        expect do
          client.user_info
        end.to raise_error(Repose::Errors::GitHubError, /Failed to fetch user info/)
      end
    end
  end
end
