# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Repose
  module AI
    # OpenAI-compatible provider for Squish local inference server.
    # Squish exposes a drop-in /v1/chat/completions endpoint at localhost:3333.
    # Configure via SQUISH_ENDPOINT and SQUISH_MODEL env vars.
    class SquishProvider
      DEFAULT_ENDPOINT = "http://localhost:3333"
      TIMEOUT = 30
      MAX_RETRIES = 2

      attr_reader :endpoint

      def initialize(endpoint: nil, model: nil)
        @endpoint = endpoint || ENV.fetch("SQUISH_ENDPOINT", DEFAULT_ENDPOINT)
        @explicit_model = model || ENV.fetch("SQUISH_MODEL", nil)
      end

      # Lazily resolved: explicit > ENV > first model from /v1/models > "squish"
      def model
        @model ||= @explicit_model || list_models.first || "squish"
      end

      def available?
        list_models.any?
      rescue StandardError
        false
      end

      def list_models
        uri = URI("#{endpoint}/v1/models")
        request = Net::HTTP::Get.new(uri)

        response = Net::HTTP.start(uri.hostname, uri.port,
                                   open_timeout: 5, read_timeout: 5) do |http|
          http.request(request)
        end

        return [] unless response.is_a?(Net::HTTPSuccess)

        body = JSON.parse(response.body)
        body["data"]&.map { |m| m["id"] } || []
      rescue StandardError
        []
      end

      def generate_description(context)
        prompt = build_description_prompt(context)
        response = call_api(prompt, max_tokens: 150)
        clean_response(response)
      end

      def generate_topics(context)
        prompt = build_topics_prompt(context)
        response = call_api(prompt, max_tokens: 100)
        parse_topics(response)
      end

      def generate_readme(context)
        prompt = build_readme_prompt(context)
        response = call_api(prompt, max_tokens: 2000)
        clean_response(response)
      end

      private

      def call_api(prompt, max_tokens: 500, temperature: 0.7)
        uri = URI("#{endpoint}/v1/chat/completions")

        payload = {
          model: model,
          messages: [{ role: "user", content: prompt }],
          max_tokens: max_tokens,
          temperature: temperature,
          stream: false
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
          raise Repose::APIError, "Squish timeout: #{e.message}" if retries > MAX_RETRIES

          sleep(2 * retries)
          retry
        rescue Errno::ECONNREFUSED
          raise Repose::APIError, "Cannot connect to Squish at #{endpoint}. Is Squish running?"
        rescue Repose::Errors::Error
          raise
        rescue StandardError => e
          raise Repose::APIError, "Squish error: #{e.message}"
        end
      end

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          body = JSON.parse(response.body)
          body.dig("choices", 0, "message", "content")&.strip || ""
        when Net::HTTPNotFound
          raise Repose::APIError, "Squish model '#{model}' not found"
        else
          raise Repose::APIError, "Squish error (#{response.code}): #{response.body}"
        end
      end

      def build_description_prompt(context)
        <<~PROMPT
          Generate a punchy GitHub repository description (max 160 characters) for:

          Name: #{context[:name]}
          Language: #{context[:language]}
          Framework: #{context[:framework]}
          Purpose: #{context[:purpose]}

          Style — 3-5 emojis, name dash tagline, concrete value props. Examples:
          "⚡💾 Vectro — Compress LLM embeddings 🧠🚀 Save memory, speed up retrieval, keep semantic accuracy 🎯"
          "🤖🗜️⚡️ Squish — Compress local LLMs once, run forever at sub-second load times. OpenAI + Ollama drop-in 🍎"
          "🐉 DREX — Tiered memory 🧠, sparse execution ⚡, learned controller that knows what to remember 💾"
          "🚀🧠 Kyro — Production RAG pipeline — hybrid retrieval 🔍, reranking 🎯, RAGAS evals 📊"

          Return ONLY the description text. No quotes. No explanation.
        PROMPT
      end

      def build_topics_prompt(context)
        <<~PROMPT
          Generate 15-20 GitHub repository topics for:

          Name: #{context[:name]}
          Language: #{context[:language]}
          Framework: #{context[:framework]}
          Purpose: #{context[:purpose]}

          Rules:
          - Highly specific technical terms only. NO generic filler.
          - Forbidden: "development", "best-practices", "programming", "software", "opensource", "tools"
          - Required: language, framework, core domain keywords, architecture patterns, specific libraries/tools
          - Good example set: "quantization, mlx, apple-silicon, llm-inference, int4, model-compression, on-device-ai, local-llm"
          - Bad example set: "development, best-practices, programming, opensource, tools"

          Return ONLY comma-separated lowercase kebab-case topics. No explanations. No numbering.
        PROMPT
      end

      def build_readme_prompt(context)
        title = context[:name].split(/[-_]/).map(&:capitalize).join(" ")
        license = context[:license] || "MIT"

        <<~PROMPT
          Generate a comprehensive README.md for:

          Name: #{context[:name]} (Title: #{title})
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

          Use proper Markdown. Be specific, not generic. Return ONLY the README content.
        PROMPT
      end

      def clean_response(text)
        return "" if text.nil? || text.empty?

        text.gsub(/^Here'?s.*?:\s*/i, "")
            .gsub(/^```\w*\n/, "")
            .gsub(/\n```$/, "")
            .strip
      end

      def parse_topics(text)
        return [] if text.nil? || text.empty?

        text.split(",").map { |t| t.strip.downcase }.reject(&:empty?).uniq.first(20)
      end
    end
  end
end
