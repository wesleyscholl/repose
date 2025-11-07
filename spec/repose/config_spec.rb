# frozen_string_literal: true

RSpec.describe Repose::Config do
  let(:config_file_path) { File.expand_path("~/.repose_test.yml") }
  let(:config) { described_class.new }

  before do
    # Override config_file_path for testing
    allow(config).to receive(:config_file_path).and_return(config_file_path)
  end

  after do
    File.delete(config_file_path) if File.exist?(config_file_path)
  end

  describe "#initialize" do
    context "when config file does not exist" do
      it "initializes with nil values" do
        expect(config.github_token).to be_nil
        expect(config.openai_api_key).to be_nil
        expect(config.default_topics).to eq([])
        expect(config.default_language).to be_nil
      end
    end

    context "when config file exists" do
      let(:config_data) do
        {
          "github_token" => "gh_token_123",
          "openai_api_key" => "sk-openai-key",
          "default_topics" => ["ruby", "cli"],
          "default_language" => "ruby"
        }
      end

      before do
        File.write(config_file_path, YAML.dump(config_data))
      end

      it "loads configuration from file" do
        expect(config.github_token).to eq("gh_token_123")
        expect(config.openai_api_key).to eq("sk-openai-key")
        expect(config.default_topics).to eq(["ruby", "cli"])
        expect(config.default_language).to eq("ruby")
      end
    end

    context "when config file is invalid YAML" do
      before do
        File.write(config_file_path, "invalid: yaml: content: [")
      end

      it "gracefully handles YAML parsing errors" do
        expect { config }.not_to raise_error
        expect(config.github_token).to be_nil
        expect(config.openai_api_key).to be_nil
      end
    end
  end

  describe "#config_file_path" do
    let(:real_config) { described_class.new }
    
    it "returns the home directory config file path" do
      expect(real_config.config_file_path).to eq(File.expand_path("~/.repose.yml"))
    end
  end

  describe "#load_config" do
    context "when file does not exist" do
      it "does not raise an error" do
        expect { config.load_config }.not_to raise_error
      end
    end

    context "when file exists with partial config" do
      before do
        File.write(config_file_path, YAML.dump({ "github_token" => "token" }))
      end

      it "loads available values and sets defaults for missing ones" do
        config.load_config
        expect(config.github_token).to eq("token")
        expect(config.default_topics).to eq([])
      end
    end
  end

  describe "#save!" do
    it "creates config file with current settings" do
      config.github_token = "gh_token_456"
      config.openai_api_key = "sk-new-key"
      config.default_topics = ["python", "api"]
      config.default_language = "python"

      config.save!

      expect(File.exist?(config_file_path)).to be true
      
      loaded_config = YAML.load_file(config_file_path)
      expect(loaded_config["github_token"]).to eq("gh_token_456")
      expect(loaded_config["openai_api_key"]).to eq("sk-new-key")
      expect(loaded_config["default_topics"]).to eq(["python", "api"])
      expect(loaded_config["default_language"]).to eq("python")
    end

    it "sets secure file permissions" do
      config.github_token = "token"
      config.save!

      file_stat = File.stat(config_file_path)
      expect(file_stat.mode & 0o777).to eq(0o600)
    end

    it "excludes nil values from saved config" do
      config.github_token = "token"
      config.openai_api_key = nil
      config.save!

      loaded_config = YAML.load_file(config_file_path)
      expect(loaded_config.keys).not_to include("openai_api_key")
      expect(loaded_config.keys).to include("github_token")
    end
  end

  describe "#valid?" do
    context "when both tokens are present" do
      before do
        config.github_token = "gh_token"
        config.openai_api_key = "openai_key"
      end

      it "returns true" do
        expect(config.valid?).to be true
      end
    end

    context "when github_token is missing" do
      before do
        config.github_token = nil
        config.openai_api_key = "openai_key"
      end

      it "returns false" do
        expect(config.valid?).to be false
      end
    end

    context "when openai_api_key is missing" do
      before do
        config.github_token = "gh_token"
        config.openai_api_key = nil
      end

      it "returns false" do
        expect(config.valid?).to be false
      end
    end

    context "when github_token is empty string" do
      before do
        config.github_token = ""
        config.openai_api_key = "openai_key"
      end

      it "returns false" do
        expect(config.valid?).to be false
      end
    end

    context "when openai_api_key is empty string" do
      before do
        config.github_token = "gh_token"
        config.openai_api_key = ""
      end

      it "returns false" do
        expect(config.valid?).to be false
      end
    end

    context "when both tokens are empty" do
      before do
        config.github_token = ""
        config.openai_api_key = ""
      end

      it "returns false" do
        expect(config.valid?).to be false
      end
    end
  end

  describe "attribute accessors" do
    it "allows setting and getting github_token" do
      config.github_token = "new_token"
      expect(config.github_token).to eq("new_token")
    end

    it "allows setting and getting openai_api_key" do
      config.openai_api_key = "new_key"
      expect(config.openai_api_key).to eq("new_key")
    end

    it "allows setting and getting default_topics" do
      config.default_topics = ["go", "microservice"]
      expect(config.default_topics).to eq(["go", "microservice"])
    end

    it "allows setting and getting default_language" do
      config.default_language = "go"
      expect(config.default_language).to eq("go")
    end
  end
end