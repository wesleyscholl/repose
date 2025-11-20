# frozen_string_literal: true

require "spec_helper"

RSpec.describe Repose::AI::OllamaProvider do
  let(:endpoint) { "http://localhost:11434" }
  let(:context) do
    {
      name: "data-processor",
      language: "Python",
      framework: "FastAPI",
      purpose: "High-performance data processing service"
    }
  end

  describe "#initialize" do
    it "uses default endpoint and model" do
      provider = described_class.new
      expect(provider.endpoint).to eq("http://localhost:11434")
      expect(provider.model).to eq("mistral")
    end

    it "accepts custom endpoint" do
      provider = described_class.new(endpoint: "http://custom:8080")
      expect(provider.endpoint).to eq("http://custom:8080")
    end

    it "accepts custom model" do
      provider = described_class.new(model: "llama3")
      expect(provider.model).to eq("llama3")
    end

    it "reads endpoint from environment" do
      ENV["OLLAMA_ENDPOINT"] = "http://env-host:9999"
      provider = described_class.new
      expect(provider.endpoint).to eq("http://env-host:9999")
      ENV.delete("OLLAMA_ENDPOINT")
    end

    it "reads model from environment" do
      ENV["OLLAMA_MODEL"] = "gemma"
      provider = described_class.new
      expect(provider.model).to eq("gemma")
      ENV.delete("OLLAMA_MODEL")
    end
  end

  describe "#available?" do
    let(:provider) { described_class.new(endpoint: endpoint) }

    it "returns true when Ollama is running" do
      stub_request(:get, "#{endpoint}/api/tags")
        .to_return(status: 200, body: '{"models": [{"name": "mistral"}]}')

      expect(provider.available?).to be true
    end

    it "returns false when Ollama is not running" do
      stub_request(:get, "#{endpoint}/api/tags")
        .to_raise(Errno::ECONNREFUSED)

      expect(provider.available?).to be false
    end

    it "returns false on timeout" do
      stub_request(:get, "#{endpoint}/api/tags")
        .to_timeout

      expect(provider.available?).to be false
    end

    it "returns false on HTTP error" do
      stub_request(:get, "#{endpoint}/api/tags")
        .to_return(status: 500)

      expect(provider.available?).to be false
    end
  end

  describe "#list_models" do
    let(:provider) { described_class.new(endpoint: endpoint) }

    it "returns list of available models" do
      response_body = {
        models: [
          { name: "mistral" },
          { name: "llama3" },
          { name: "gemma" }
        ]
      }.to_json

      stub_request(:get, "#{endpoint}/api/tags")
        .to_return(status: 200, body: response_body)

      models = provider.list_models
      expect(models).to eq(["mistral", "llama3", "gemma"])
    end

    it "returns empty array when no models" do
      stub_request(:get, "#{endpoint}/api/tags")
        .to_return(status: 200, body: '{"models": []}')

      models = provider.list_models
      expect(models).to eq([])
    end

    it "returns empty array on error" do
      stub_request(:get, "#{endpoint}/api/tags")
        .to_raise(Errno::ECONNREFUSED)

      models = provider.list_models
      expect(models).to eq([])
    end
  end

  describe "#pull_model" do
    let(:provider) { described_class.new(endpoint: endpoint) }

    it "pulls a model successfully" do
      stub_request(:post, "#{endpoint}/api/pull")
        .with(body: '{"name":"llama3"}')
        .to_return(status: 200, body: '{"status": "success"}')

      result = provider.pull_model("llama3")
      expect(result).to be true
    end

    it "raises error on failure" do
      stub_request(:post, "#{endpoint}/api/pull")
        .to_raise(Errno::ECONNREFUSED)

      expect { provider.pull_model("llama3") }
        .to raise_error(Repose::APIError, /Failed to pull/)
    end
  end

  describe "#generate_description" do
    let(:provider) { described_class.new(endpoint: endpoint) }

    context "when API responds successfully" do
      it "returns cleaned description" do
        response_body = {
          response: "A high-performance data processing service built with Python and FastAPI"
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_description(context)
        expect(result).to eq("A high-performance data processing service built with Python and FastAPI")
      end

      it "removes common prefixes" do
        response_body = {
          response: "Here's a description: Fast data processing service"
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_description(context)
        expect(result).to eq("Fast data processing service")
      end

      it "removes markdown code blocks" do
        response_body = {
          response: "```\nData processing service\n```"
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_description(context)
        expect(result).to eq("Data processing service")
      end
    end

    context "when API returns error" do
      it "raises error when Ollama not running" do
        stub_request(:post, "#{endpoint}/api/generate")
          .to_raise(Errno::ECONNREFUSED)

        expect { provider.generate_description(context) }
          .to raise_error(Repose::APIError, /Cannot connect to Ollama/)
      end

      it "raises error when model not found" do
        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 404, body: '{"error": "model not found"}')

        expect { provider.generate_description(context) }
          .to raise_error(Repose::APIError, /model.*not found/)
      end

      it "raises error on generic HTTP error" do
        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 500, body: '{"error": "server error"}')

        expect { provider.generate_description(context) }
          .to raise_error(Repose::APIError, /Ollama error/)
      end
    end

    context "when API times out" do
      it "retries and eventually raises error" do
        stub_request(:post, "#{endpoint}/api/generate")
          .to_timeout
          .times(3) # Initial + 2 retries

        expect { provider.generate_description(context) }
          .to raise_error(Repose::APIError, /timeout/)
      end

      it "succeeds on retry" do
        response_body = { response: "Success" }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_timeout
          .then
          .to_return(status: 200, body: response_body)

        result = provider.generate_description(context)
        expect(result).to eq("Success")
      end
    end
  end

  describe "#generate_topics" do
    let(:provider) { described_class.new(endpoint: endpoint) }

    context "when API responds successfully" do
      it "parses comma-separated topics" do
        response_body = {
          response: "python, fastapi, data-processing, api, performance"
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq(["python", "fastapi", "data-processing", "api", "performance"])
      end

      it "removes duplicates" do
        response_body = {
          response: "python, api, python, fastapi, api"
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq(["python", "api", "fastapi"])
      end

      it "limits to 8 topics" do
        response_body = {
          response: "a, b, c, d, e, f, g, h, i, j, k, l"
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result.length).to eq(8)
      end

      it "handles whitespace" do
        response_body = {
          response: " python , fastapi  ,  api "
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq(["python", "fastapi", "api"])
      end

      it "converts to lowercase" do
        response_body = {
          response: "Python, FASTAPI, Api"
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq(["python", "fastapi", "api"])
      end

      it "filters empty topics" do
        response_body = {
          response: "python, , fastapi, , api"
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq(["python", "fastapi", "api"])
      end
    end

    context "when API returns empty response" do
      it "returns empty array" do
        response_body = { response: "" }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq([])
      end
    end
  end

  describe "#generate_readme" do
    let(:provider) { described_class.new(endpoint: endpoint) }

    context "when API responds successfully" do
      it "returns README content" do
        readme_content = <<~README
          # Data Processor

          High-performance data processing service.

          ## Features
          - Fast processing
          - Built with FastAPI
          - RESTful API
        README

        response_body = { response: readme_content }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_readme(context)
        expect(result).to include("# Data Processor")
        expect(result).to include("## Features")
      end

      it "removes common prefixes" do
        response_body = {
          response: "Here's the README:\n\n# Data Processor\n\nContent here."
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_readme(context)
        expect(result).to eq("# Data Processor\n\nContent here.")
      end

      it "cleans markdown artifacts" do
        response_body = {
          response: "```markdown\n# Data Processor\n\nREADME content\n```"
        }.to_json

        stub_request(:post, "#{endpoint}/api/generate")
          .to_return(status: 200, body: response_body)

        result = provider.generate_readme(context)
        expect(result).to eq("# Data Processor\n\nREADME content")
      end
    end
  end
end
