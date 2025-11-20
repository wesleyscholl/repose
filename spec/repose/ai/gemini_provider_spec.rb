# frozen_string_literal: true

require "spec_helper"

RSpec.describe Repose::AI::GeminiProvider do
  let(:api_key) { "test-api-key-123" }
  let(:context) do
    {
      name: "awesome-api",
      language: "Ruby",
      framework: "Sinatra",
      purpose: "RESTful API for data processing"
    }
  end

  describe "#initialize" do
    it "accepts an API key" do
      provider = described_class.new(api_key: api_key, model: "gemini-1.5-pro")
      expect(provider.api_key).to eq(api_key)
      expect(provider.model).to eq("gemini-1.5-pro")
    end

    it "reads API key from environment" do
      ENV["GEMINI_API_KEY"] = api_key
      provider = described_class.new
      expect(provider.api_key).to eq(api_key)
      ENV.delete("GEMINI_API_KEY")
    end

    it "uses default model if not specified" do
      provider = described_class.new(api_key: api_key)
      expect(provider.model).to eq("gemini-1.5-flash")
    end

    it "raises error if no API key provided" do
      ENV.delete("GEMINI_API_KEY")
      expect { described_class.new }.to raise_error(Repose::ConfigurationError, /API key not configured/)
    end

    it "raises error if API key is empty" do
      expect { described_class.new(api_key: "") }.to raise_error(Repose::ConfigurationError)
    end
  end

  describe "#available?" do
    let(:provider) { described_class.new(api_key: api_key) }

    it "returns true when API responds successfully" do
      stub_request(:get, %r{https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash\?key=.*})
        .to_return(status: 200, body: '{"name": "models/gemini-1.5-flash"}')

      expect(provider.available?).to be true
    end

    it "returns false when API is unreachable" do
      stub_request(:get, %r{https://generativelanguage.googleapis.com/v1beta/models/.*})
        .to_timeout

      expect(provider.available?).to be false
    end

    it "returns false on HTTP error" do
      stub_request(:get, %r{https://generativelanguage.googleapis.com/v1beta/models/.*})
        .to_return(status: 500)

      expect(provider.available?).to be false
    end

    it "returns false if API key is invalid" do
      stub_request(:get, %r{https://generativelanguage.googleapis.com/v1beta/models/.*})
        .to_return(status: 401)

      expect(provider.available?).to be false
    end
  end

  describe "#generate_description" do
    let(:provider) { described_class.new(api_key: api_key) }

    context "when API responds successfully" do
      it "returns cleaned description text" do
        response_body = {
          candidates: [{
            content: {
              parts: [{
                text: "A powerful RESTful API for data processing built with Ruby and Sinatra"
              }]
            }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 200, body: response_body)

        result = provider.generate_description(context)
        expect(result).to eq("A powerful RESTful API for data processing built with Ruby and Sinatra")
      end

      it "removes markdown code blocks" do
        response_body = {
          candidates: [{
            content: {
              parts: [{
                text: "```\nRESTful API for data processing\n```"
              }]
            }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 200, body: response_body)

        result = provider.generate_description(context)
        expect(result).to eq("RESTful API for data processing")
      end
    end

    context "when API returns error" do
      it "raises AuthenticationError on 401" do
        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 401, body: '{"error": "Invalid API key"}')

        expect { provider.generate_description(context) }
          .to raise_error(Repose::AuthenticationError, /Invalid Gemini API key/)
      end

      it "raises RateLimitError on 429" do
        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 429, body: '{"error": "Rate limit exceeded"}')

        expect { provider.generate_description(context) }
          .to raise_error(Repose::RateLimitError, /rate limit exceeded/)
      end

      it "raises APIError on other HTTP errors" do
        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 500, body: '{"error": "Internal error"}')

        expect { provider.generate_description(context) }
          .to raise_error(Repose::APIError, /Gemini API error/)
      end
    end

    context "when API times out" do
      it "retries and raises error after max retries" do
        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_timeout
          .times(4) # Initial + 3 retries

        expect { provider.generate_description(context) }
          .to raise_error(Repose::APIError, /timeout/)
      end

      it "succeeds on retry" do
        response_body = {
          candidates: [{
            content: { parts: [{ text: "Success after retry" }] }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_timeout
          .times(2)
          .then
          .to_return(status: 200, body: response_body)

        result = provider.generate_description(context)
        expect(result).to eq("Success after retry")
      end
    end
  end

  describe "#generate_topics" do
    let(:provider) { described_class.new(api_key: api_key) }

    context "when API responds successfully" do
      it "parses comma-separated topics" do
        response_body = {
          candidates: [{
            content: {
              parts: [{
                text: "ruby, sinatra, api, rest, data-processing"
              }]
            }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq(["ruby", "sinatra", "api", "rest", "data-processing"])
      end

      it "removes duplicates" do
        response_body = {
          candidates: [{
            content: {
              parts: [{
                text: "ruby, api, ruby, api, sinatra"
              }]
            }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq(["ruby", "api", "sinatra"])
      end

      it "limits to 8 topics" do
        response_body = {
          candidates: [{
            content: {
              parts: [{
                text: "a, b, c, d, e, f, g, h, i, j, k"
              }]
            }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result.length).to eq(8)
      end

      it "handles whitespace in topics" do
        response_body = {
          candidates: [{
            content: {
              parts: [{
                text: " ruby , sinatra  ,  api "
              }]
            }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq(["ruby", "sinatra", "api"])
      end

      it "converts topics to lowercase" do
        response_body = {
          candidates: [{
            content: {
              parts: [{
                text: "Ruby, SINATRA, Api"
              }]
            }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq(["ruby", "sinatra", "api"])
      end
    end

    context "when API returns empty response" do
      it "returns empty array" do
        response_body = {
          candidates: [{
            content: {
              parts: [{
                text: ""
              }]
            }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 200, body: response_body)

        result = provider.generate_topics(context)
        expect(result).to eq([])
      end
    end
  end

  describe "#generate_readme" do
    let(:provider) { described_class.new(api_key: api_key) }

    context "when API responds successfully" do
      it "returns README content" do
        readme_content = <<~README
          # Awesome API

          A powerful RESTful API for data processing.

          ## Features
          - Fast data processing
          - RESTful endpoints
          - Built with Sinatra
        README

        response_body = {
          candidates: [{
            content: {
              parts: [{
                text: readme_content
              }]
            }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 200, body: response_body)

        result = provider.generate_readme(context)
        expect(result).to include("# Awesome API")
        expect(result).to include("## Features")
      end

      it "cleans markdown code blocks" do
        response_body = {
          candidates: [{
            content: {
              parts: [{
                text: "```markdown\n# Awesome API\n\nREADME content\n```"
              }]
            }
          }]
        }.to_json

        stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.*:generateContent})
          .to_return(status: 200, body: response_body)

        result = provider.generate_readme(context)
        expect(result).to eq("# Awesome API\n\nREADME content")
      end
    end
  end
end
