# frozen_string_literal: true

RSpec.describe Repose::AIGenerator do
  let(:generator) { described_class.new }

  describe "#initialize" do
    it "creates a new instance without errors" do
      expect { generator }.not_to raise_error
    end

    it "accepts provider parameter" do
      gen = described_class.new(provider: :none)
      expect(gen.provider).to be_nil
    end

    context "with Gemini provider" do
      before do
        ENV["GEMINI_API_KEY"] = "test-key"
        allow_any_instance_of(Repose::AI::GeminiProvider).to receive(:available?).and_return(true)
      end

      after do
        ENV.delete("GEMINI_API_KEY")
      end

      it "initializes Gemini provider when specified" do
        gen = described_class.new(provider: :gemini)
        expect(gen.provider).to be_a(Repose::AI::GeminiProvider)
      end

      it "auto-detects Gemini when available and no provider specified" do
        gen = described_class.new
        expect(gen.provider).to be_a(Repose::AI::GeminiProvider)
      end
    end

    context "with Ollama provider" do
      before do
        ENV.delete("GEMINI_API_KEY")
        allow_any_instance_of(Repose::AI::OllamaProvider).to receive(:available?).and_return(true)
      end

      it "initializes Ollama provider when specified" do
        gen = described_class.new(provider: :ollama)
        expect(gen.provider).to be_a(Repose::AI::OllamaProvider)
      end

      it "falls back to Ollama when Gemini unavailable" do
        gen = described_class.new
        expect(gen.provider).to be_a(Repose::AI::OllamaProvider)
      end
    end

    context "with no AI provider available" do
      before do
        ENV.delete("GEMINI_API_KEY")
        allow_any_instance_of(Repose::AI::OllamaProvider).to receive(:available?).and_return(false)
      end

      it "uses nil provider for fallback mode" do
        gen = described_class.new
        expect(gen.provider).to be_nil
      end
    end

    it "raises error for unknown provider" do
      expect { described_class.new(provider: :unknown) }.to raise_error(ArgumentError)
    end
  end

  describe "#use_ai?" do
    it "returns false when provider is nil" do
      gen = described_class.new(provider: :none)
      expect(gen.use_ai?).to be false
    end

    context "with AI provider" do
      before do
        ENV["GEMINI_API_KEY"] = "test-key"
        allow_any_instance_of(Repose::AI::GeminiProvider).to receive(:available?).and_return(true)
      end

      after do
        ENV.delete("GEMINI_API_KEY")
      end

      it "returns true when provider is set" do
        gen = described_class.new(provider: :gemini)
        expect(gen.use_ai?).to be true
      end
    end
  end

  describe "#generate" do
    let(:context) do
      {
        name: "web-scraper",
        language: "ruby",
        framework: "rails",
        description: nil,
        topics: [],
        purpose: "scraping e-commerce websites"
      }
    end

    let(:result) { generator.generate(context) }

    it "returns a hash with required keys" do
      expect(result.keys).to contain_exactly(:name, :description, :topics, :readme)
    end

    it "preserves the repository name" do
      expect(result[:name]).to eq("web-scraper")
    end

    it "generates a description" do
      expect(result[:description]).to be_a(String)
      expect(result[:description]).not_to be_empty
    end

    it "generates topics array" do
      expect(result[:topics]).to be_an(Array)
      expect(result[:topics]).not_to be_empty
    end

    it "generates a README" do
      expect(result[:readme]).to be_a(String)
      expect(result[:readme]).not_to be_empty
    end
  end

  describe "#generate_description" do
    let(:method) { generator.method(:generate_description) }

    context "with basic context" do
      let(:context) { { name: "test-app", language: "python" } }

      it "generates a basic description" do
        result = method.call(context)
        expect(result).to eq("A python project")
      end
    end

    context "with framework" do
      let(:context) { { name: "api-server", language: "ruby", framework: "sinatra" } }

      it "includes framework in description" do
        result = method.call(context)
        expect(result).to eq("A ruby sinatra project")
      end
    end

    context "with purpose" do
      let(:context) { 
        { 
          name: "data-processor", 
          language: "python", 
          purpose: "processing CSV files" 
        } 
      }

      it "includes purpose in description" do
        result = method.call(context)
        expect(result).to eq("A python project for processing csv files")
      end
    end

    context "with framework and purpose" do
      let(:context) { 
        { 
          name: "blog-api", 
          language: "ruby", 
          framework: "rails",
          purpose: "managing blog posts" 
        } 
      }

      it "includes both framework and purpose" do
        result = method.call(context)
        expect(result).to eq("A ruby rails project for managing blog posts")
      end
    end

    context "with empty purpose" do
      let(:context) { 
        { 
          name: "app", 
          language: "javascript", 
          purpose: "" 
        } 
      }

      it "ignores empty purpose" do
        result = method.call(context)
        expect(result).to eq("A javascript project")
      end
    end
  end

  describe "#generate_topics" do
    let(:method) { generator.method(:generate_topics) }

    context "with language only" do
      let(:context) { { name: "simple-app", language: "go" } }

      it "includes language as topic" do
        result = method.call(context)
        expect(result).to include("go")
      end
    end

    context "with language and framework" do
      let(:context) { { name: "web-app", language: "javascript", framework: "React" } }

      it "includes both language and framework" do
        result = method.call(context)
        expect(result).to include("javascript", "react")
      end
    end

    context "with API in name" do
      let(:context) { { name: "user-api", language: "python" } }

      it "adds api topic" do
        result = method.call(context)
        expect(result).to include("python", "api")
      end
    end

    context "with web-related framework" do
      let(:context) { { name: "blog", language: "ruby", framework: "Rails" } }

      it "adds web topic" do
        result = method.call(context)
        expect(result).to include("ruby", "rails", "web")
      end
    end

    context "with CLI in name" do
      let(:context) { { name: "deploy-cli", language: "go" } }

      it "adds cli topic" do
        result = method.call(context)
        expect(result).to include("go", "cli")
      end
    end

    context "with command in name" do
      let(:context) { { name: "git-command", language: "rust" } }

      it "adds cli topic" do
        result = method.call(context)
        expect(result).to include("rust", "cli")
      end
    end

    context "with tool in name" do
      let(:context) { { name: "build-tool", language: "java" } }

      it "adds tool topic" do
        result = method.call(context)
        expect(result).to include("java", "tool")
      end
    end

    context "with util in name" do
      let(:context) { { name: "string-utils", language: "python" } }

      it "adds tool topic" do
        result = method.call(context)
        expect(result).to include("python", "tool")
      end
    end

    it "limits topics to 8 items" do
      # This would be hard to test with current implementation, 
      # but we ensure the method doesn't return more than 8 topics
      context = { 
        name: "api-cli-tool-web-util", 
        language: "ruby", 
        framework: "rails" 
      }
      result = method.call(context)
      expect(result.length).to be <= 8
    end

    it "returns unique topics" do
      context = { name: "web-web", language: "ruby", framework: "rails" }
      result = method.call(context)
      expect(result).to eq(result.uniq)
    end
  end

  describe "#generate_readme" do
    let(:method) { generator.method(:generate_readme) }

    context "with basic context" do
      let(:context) { { name: "test-app", language: "ruby" } }
      let(:result) { method.call(context) }

      it "generates README with proper title" do
        expect(result).to include("# Test App")
      end

      it "includes project description" do
        expect(result).to include("A ruby project")
      end

      it "includes basic sections" do
        expect(result).to include("## Installation")
        expect(result).to include("## Usage")
        expect(result).to include("## Contributing")
        expect(result).to include("## License")
      end

      it "includes git clone instructions" do
        expect(result).to include("git clone")
        expect(result).to include("test-app")
      end
    end

    context "with framework" do
      let(:context) { { name: "api-server", language: "python", framework: "django" } }
      let(:result) { method.call(context) }

      it "includes framework in description" do
        expect(result).to include("A python django project")
      end
    end

    context "with purpose" do
      let(:context) { 
        { 
          name: "data-tool", 
          language: "go", 
          purpose: "data analysis" 
        } 
      }
      let(:result) { method.call(context) }

      it "includes purpose in description" do
        expect(result).to include("for data analysis")
      end
    end
  end

  describe "#language_specific_install_instructions" do
    let(:method) { generator.method(:language_specific_install_instructions) }

    it "returns bundle install for ruby" do
      result = method.call("ruby")
      expect(result).to include("bundle install")
    end

    it "returns pip install for python" do
      result = method.call("python")
      expect(result).to include("pip install -r requirements.txt")
    end

    it "returns npm install for javascript" do
      result = method.call("javascript")
      expect(result).to include("npm install")
    end

    it "returns npm install for typescript" do
      result = method.call("typescript")
      expect(result).to include("npm install")
    end

    it "returns go mod download for go" do
      result = method.call("go")
      expect(result).to include("go mod download")
    end

    it "returns cargo build for rust" do
      result = method.call("rust")
      expect(result).to include("cargo build")
    end

    it "returns empty string for unknown language" do
      result = method.call("unknown")
      expect(result).to eq("")
    end

    it "handles nil language" do
      result = method.call(nil)
      expect(result).to eq("")
    end

    it "handles case insensitive language names" do
      result = method.call("RUBY")
      expect(result).to include("bundle install")
    end
  end
end