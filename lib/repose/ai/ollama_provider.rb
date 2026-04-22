# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Repose
  module AI
    class OllamaProvider
      DEFAULT_ENDPOINT = "http://localhost:11434"
      DEFAULT_MODEL = "mistral"
      MAX_RETRIES = 2
      TIMEOUT = 45

      attr_reader :endpoint, :model

      def initialize(endpoint: nil, model: nil)
        @endpoint = endpoint || ENV["OLLAMA_ENDPOINT"] || DEFAULT_ENDPOINT
        @model = model || ENV["OLLAMA_MODEL"] || DEFAULT_MODEL
      end

      def generate_description(context)
        prompt = build_description_prompt(context)
        response = call_api(prompt, max_tokens: 100)
        clean_response(response)
      end

      def generate_topics(context)
        prompt = build_topics_prompt(context)
        response = call_api(prompt, max_tokens: 50)
        parse_topics(response)
      end

      def generate_readme(context)
        prompt = build_readme_prompt(context)
        response = call_api(prompt, max_tokens: 2000)
        clean_response(response)
      end

      def available?
        list_models.any?
      rescue StandardError
        false
      end

      def list_models
        uri = URI("#{endpoint}/api/tags")
        request = Net::HTTP::Get.new(uri)

        response = Net::HTTP.start(uri.hostname, uri.port,
                                   open_timeout: 5, read_timeout: 5) do |http|
          http.request(request)
        end

        return [] unless response.is_a?(Net::HTTPSuccess)

        body = JSON.parse(response.body)
        body["models"]&.map { |m| m["name"] } || []
      rescue StandardError
        []
      end

      def pull_model(model_name = @model)
        uri = URI("#{endpoint}/api/pull")
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request.body = { name: model_name }.to_json

        response = Net::HTTP.start(uri.hostname, uri.port,
                                   open_timeout: 300, read_timeout: 300) do |http|
          http.request(request)
        end

        response.is_a?(Net::HTTPSuccess)
      rescue StandardError => e
        raise Repose::APIError, "Failed to pull Ollama model: #{e.message}"
      end

      private

      def call_api(prompt, max_tokens: 500, temperature: 0.7)
        uri = URI("#{endpoint}/api/generate")

        payload = {
          model: model,
          prompt: prompt,
          stream: false,
          options: {
            temperature: temperature,
            num_predict: max_tokens,
            top_p: 0.9,
            top_k: 40
          }
        }

        retries = 0
        begin
          request = Net::HTTP::Post.new(uri)
          request["Content-Type"] = "application/json"
          request.body = payload.to_json

          response = Net::HTTP.start(uri.hostname, uri.port,
                                     open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
            http.request(request)
          end

          handle_response(response)
        rescue Net::OpenTimeout, Net::ReadTimeout => e
          retries += 1
          raise Repose::APIError, "Ollama timeout: #{e.message}" if retries > MAX_RETRIES

          sleep(3 * retries) # Linear backoff
          retry
        rescue Errno::ECONNREFUSED
          raise Repose::APIError, "Cannot connect to Ollama at #{endpoint}. Is Ollama running?"
        rescue StandardError => e
          raise Repose::APIError, "Ollama error: #{e.message}"
        end
      end

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          body = JSON.parse(response.body)
          body["response"]&.strip || ""
        when Net::HTTPNotFound
          raise Repose::APIError, "Ollama model '#{model}' not found. Run: ollama pull #{model}"
        else
          raise Repose::APIError, "Ollama error (#{response.code}): #{response.body}"
        end
      end

      def build_description_prompt(context)
        <<~PROMPT
          Generate a punchy GitHub repository description (max 160 characters) for:

          Repository: #{context[:name]}
          Language: #{context[:language]}
          Framework: #{context[:framework]}
          Purpose: #{context[:purpose]}

          Style — 3-5 emojis, name dash tagline, concrete value props. Examples:
          "⚡💾 Vectro — Compress LLM embeddings 🧠🚀 Save memory, speed up retrieval, keep semantic accuracy 🎯"
          "🤖🗜️⚡️ Squish — Compress local LLMs once, run forever at sub-second load times. OpenAI + Ollama drop-in 🍎"
          "🚀🧠 Kyro — Production RAG pipeline — hybrid retrieval 🔍, reranking 🎯, RAGAS evals 📊"

          Return ONLY the description text. No quotes. No explanation.
        PROMPT
      end

      def build_topics_prompt(context)
        <<~PROMPT
          Generate 15-20 GitHub repository topics for:

          Repository: #{context[:name]}
          Language: #{context[:language]}
          Framework: #{context[:framework]}
          Purpose: #{context[:purpose]}

          Rules:
          - Highly specific technical terms only. NO generic filler.
          - Forbidden: "development", "best-practices", "programming", "software", "opensource", "tools"
          - Required: language, framework, core domain keywords, architecture patterns, specific libs/tools
          - Good: "quantization, mlx, apple-silicon, llm-inference, int4, model-compression, on-device-ai"
          - Bad: "development, best-practices, programming, opensource, tools"

          Return ONLY comma-separated lowercase kebab-case topics. No explanations. No numbering.
        PROMPT
      end

      def build_readme_prompt(context)
        title = context[:name].split(/[-_]/).map(&:capitalize).join(" ")
        license = context[:license] || "MIT"

        <<~PROMPT
          Generate a comprehensive README.md for:

          Repository: #{context[:name]} (Display as: #{title})
          Language: #{context[:language]}
          Framework: #{context[:framework]}
          Purpose: #{context[:purpose]}
          License: #{license}

          Required structure (use emojis throughout):
          1. # Title with emoji tagline
          2. Shields.io badge row: language, license, build status
          3. One-paragraph hero description with emoji flair
          4. ## ✨ Features — 4-6 specific bullets with emojis
          5. ## 🚀 Quick Start — clone + language-appropriate install command
          6. ## 💻 Usage — concrete code example in a fenced block
          7. ## 🤝 Contributing — fork/branch/PR steps
          8. ## 📄 License — #{license}

          Use proper Markdown. Be specific. Return ONLY the README content.
        PROMPT
      end

      def clean_response(text)
        return "" if text.nil? || text.empty?

        # Remove common artifacts
        text.gsub(/^Here's.*?:\s*/i, "")
            .gsub(/^```\w*\n/, "")
            .gsub(/\n```$/, "")
            .strip
      end

      def parse_topics(text)
        return [] if text.nil? || text.empty?

        # Extract comma-separated values
        topics = text.split(",").map { |t| t.strip.downcase }

        # Remove duplicates, filter out empty, limit to 20
        topics.reject(&:empty?).uniq.first(20)
      end
    end
  end
end
