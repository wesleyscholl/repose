# frozen_string_literal: true

require "spec_helper"

RSpec.describe Repose::AI::SquishProvider do
  let(:endpoint) { "http://localhost:3333" }
  let(:model_name) { "qwen3:8b" }
  let(:context) do
    {
      name: "squish",
      language: "Python",
      framework: "MLX",
      purpose: "compress local LLMs for on-device inference"
    }
  end

  describe "#initialize" do
    it "uses default endpoint when none given" do
      provider = described_class.new
      expect(provider.endpoint).to eq("http://localhost:3333")
    end

    it "accepts a custom endpoint" do
      provider = described_class.new(endpoint: "http://localhost:9999")
      expect(provider.endpoint).to eq("http://localhost:9999")
    end

    it "reads endpoint from SQUISH_ENDPOINT env var" do
      ENV["SQUISH_ENDPOINT"] = "http://custom:8080"
      provider = described_class.new
      expect(provider.endpoint).to eq("http://custom:8080")
      ENV.delete("SQUISH_ENDPOINT")
    end

    it "reads model from SQUISH_MODEL env var" do
      ENV["SQUISH_MODEL"] = "qwen3:8b"
      provider = described_class.new
      # Accessing #model should use the env var without hitting /v1/models
      stub_request(:get, "#{endpoint}/v1/models").to_return(status: 200, body: '{"data":[]}')
      expect(provider.model).to eq("qwen3:8b")
      ENV.delete("SQUISH_MODEL")
    end
  end

  describe "#model" do
    it "returns explicit model when given" do
      provider = described_class.new(model: "llama3:8b")
      expect(provider.model).to eq("llama3:8b")
    end

    it "detects model from /v1/models when not specified" do
      stub_request(:get, "#{endpoint}/v1/models")
        .to_return(status: 200, body: { data: [{ id: "qwen3:8b" }, { id: "llama3:1b" }] }.to_json)

      provider = described_class.new
      expect(provider.model).to eq("qwen3:8b")
    end

    it "falls back to 'squish' when no models available" do
      stub_request(:get, "#{endpoint}/v1/models")
        .to_return(status: 200, body: '{"data":[]}')

      provider = described_class.new
      expect(provider.model).to eq("squish")
    end
  end

  describe "#available?" do
    let(:provider) { described_class.new }

    it "returns true when /v1/models lists at least one model" do
      stub_request(:get, "#{endpoint}/v1/models")
        .to_return(status: 200, body: { data: [{ id: "qwen3:8b" }] }.to_json)

      expect(provider.available?).to be true
    end

    it "returns false when model list is empty" do
      stub_request(:get, "#{endpoint}/v1/models")
        .to_return(status: 200, body: '{"data":[]}')

      expect(provider.available?).to be false
    end

    it "returns false when server is unreachable" do
      stub_request(:get, "#{endpoint}/v1/models").to_timeout
      expect(provider.available?).to be false
    end

    it "returns false on HTTP error" do
      stub_request(:get, "#{endpoint}/v1/models").to_return(status: 500)
      expect(provider.available?).to be false
    end
  end

  describe "#list_models" do
    let(:provider) { described_class.new }

    it "returns array of model ids" do
      stub_request(:get, "#{endpoint}/v1/models")
        .to_return(status: 200, body: {
          data: [{ id: "qwen3:8b" }, { id: "llama3:1b" }]
        }.to_json)

      expect(provider.list_models).to eq(%w[qwen3:8b llama3:1b])
    end

    it "returns empty array on network failure" do
      stub_request(:get, "#{endpoint}/v1/models").to_timeout
      expect(provider.list_models).to eq([])
    end
  end

  describe "#generate_description" do
    let(:provider) { described_class.new(model: model_name) }

    context "when API responds successfully" do
      it "returns the description content" do
        response_body = {
          choices: [{ message: { content: "🤖🗜️⚡️ Squish — compress local LLMs 🍎" } }]
        }.to_json

        stub_request(:post, "#{endpoint}/v1/chat/completions")
          .to_return(status: 200, body: response_body)

        result = provider.generate_description(context)
        expect(result).to eq("🤖🗜️⚡️ Squish — compress local LLMs 🍎")
      end

      it "strips leading 'Here's' preamble" do
        response_body = {
          choices: [{ message: { content: "Here's the description:\n🤖 Squish rocks" } }]
        }.to_json

        stub_request(:post, "#{endpoint}/v1/chat/completions")
          .to_return(status: 200, body: response_body)

        result = provider.generate_description(context)
        expect(result).to eq("🤖 Squish rocks")
      end
    end

    context "when server is unreachable" do
      it "raises APIError on connection refused" do
        stub_request(:post, "#{endpoint}/v1/chat/completions")
          .to_raise(Errno::ECONNREFUSED)

        expect { provider.generate_description(context) }
          .to raise_error(Repose::APIError, /Cannot connect to Squish/)
      end
    end

    context "when API returns HTTP error" do
      it "raises APIError on non-2xx response" do
        stub_request(:post, "#{endpoint}/v1/chat/completions")
          .to_return(status: 500, body: "Internal error")

        expect { provider.generate_description(context) }
          .to raise_error(Repose::APIError, /Squish error \(500\)/)
      end

      it "raises APIError with model name on 404" do
        stub_request(:post, "#{endpoint}/v1/chat/completions")
          .to_return(status: 404, body: "Not found")

        expect { provider.generate_description(context) }
          .to raise_error(Repose::APIError, /qwen3:8b/)
      end
    end

    context "when API times out" do
      it "retries and raises APIError after max retries" do
        stub_request(:post, "#{endpoint}/v1/chat/completions")
          .to_timeout
          .times(3)

        expect { provider.generate_description(context) }
          .to raise_error(Repose::APIError, /timeout/)
      end

      it "succeeds on retry after initial timeout" do
        response_body = {
          choices: [{ message: { content: "🚀 Success on retry" } }]
        }.to_json

        stub_request(:post, "#{endpoint}/v1/chat/completions")
          .to_timeout
          .times(2)
          .then
          .to_return(status: 200, body: response_body)

        result = provider.generate_description(context)
        expect(result).to eq("🚀 Success on retry")
      end
    end
  end

  describe "#generate_topics" do
    let(:provider) { described_class.new(model: model_name) }

    it "parses comma-separated topics" do
      response_body = {
        choices: [{ message: { content: "python, mlx, quantization, apple-silicon, llm-inference" } }]
      }.to_json

      stub_request(:post, "#{endpoint}/v1/chat/completions")
        .to_return(status: 200, body: response_body)

      result = provider.generate_topics(context)
      expect(result).to eq(%w[python mlx quantization apple-silicon llm-inference])
    end

    it "removes duplicates and limits to 20" do
      topics = (1..25).map { |i| "topic-#{i}" }.join(", ")
      response_body = {
        choices: [{ message: { content: topics } }]
      }.to_json

      stub_request(:post, "#{endpoint}/v1/chat/completions")
        .to_return(status: 200, body: response_body)

      result = provider.generate_topics(context)
      expect(result.length).to be <= 20
      expect(result).to eq(result.uniq)
    end
  end

  describe "#generate_readme" do
    let(:provider) { described_class.new(model: model_name) }

    it "returns README content" do
      readme = "# 🤖 Squish\n\n> Compress local LLMs\n\n## ✨ Features\n"
      response_body = {
        choices: [{ message: { content: readme } }]
      }.to_json

      stub_request(:post, "#{endpoint}/v1/chat/completions")
        .to_return(status: 200, body: response_body)

      result = provider.generate_readme(context)
      expect(result).to include("Squish")
      expect(result).to include("Features")
    end
  end
end
