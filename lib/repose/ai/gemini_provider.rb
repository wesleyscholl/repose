# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Repose
  module AI
    class GeminiProvider
      API_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models"
      DEFAULT_MODEL = "gemini-1.5-flash"
      MAX_RETRIES = 3
      TIMEOUT = 30

      attr_reader :api_key, :model

      def initialize(api_key: nil, model: DEFAULT_MODEL)
        @api_key = api_key || ENV["GEMINI_API_KEY"]
        @model = model
        
        raise Repose::ConfigurationError, "Gemini API key not configured" if @api_key.nil? || @api_key.empty?
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
        response = call_api(prompt, max_tokens: 1000)
        clean_response(response)
      end

      def available?
        return false if @api_key.nil? || @api_key.empty?
        
        # Quick health check
        uri = URI("#{API_ENDPOINT}/#{model}?key=#{api_key}")
        request = Net::HTTP::Get.new(uri)
        
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
          http.request(request)
        end
        
        response.is_a?(Net::HTTPSuccess)
      rescue StandardError
        false
      end

      private

      def call_api(prompt, max_tokens: 500, temperature: 0.7)
        uri = URI("#{API_ENDPOINT}/#{model}:generateContent?key=#{api_key}")
        
        payload = {
          contents: [
            {
              parts: [
                { text: prompt }
              ]
            }
          ],
          generationConfig: {
            temperature: temperature,
            maxOutputTokens: max_tokens,
            topP: 0.95,
            topK: 40
          }
        }

        retries = 0
        begin
          request = Net::HTTP::Post.new(uri)
          request["Content-Type"] = "application/json"
          request.body = payload.to_json

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, 
                                     open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
            http.request(request)
          end

          handle_response(response)
        rescue Net::OpenTimeout, Net::ReadTimeout => e
          retries += 1
          raise Repose::APIError, "Gemini API timeout: #{e.message}" if retries > MAX_RETRIES
          
          sleep(2**retries) # Exponential backoff
          retry
        rescue StandardError => e
          raise Repose::APIError, "Gemini API error: #{e.message}"
        end
      end

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          body = JSON.parse(response.body)
          extract_text_from_response(body)
        when Net::HTTPUnauthorized
          raise Repose::AuthenticationError, "Invalid Gemini API key"
        when Net::HTTPTooManyRequests
          raise Repose::RateLimitError, "Gemini API rate limit exceeded"
        else
          raise Repose::APIError, "Gemini API error (#{response.code}): #{response.body}"
        end
      end

      def extract_text_from_response(body)
        return "" unless body.dig("candidates", 0, "content", "parts", 0, "text")
        
        body.dig("candidates", 0, "content", "parts", 0, "text").strip
      end

      def build_description_prompt(context)
        <<~PROMPT
          Generate a concise, professional GitHub repository description (max 100 characters) for:
          
          Repository name: #{context[:name]}
          Language: #{context[:language]}
          Framework: #{context[:framework]}
          Purpose: #{context[:purpose]}
          
          Return only the description text, no quotes or extra formatting.
        PROMPT
      end

      def build_topics_prompt(context)
        <<~PROMPT
          Generate 5-8 relevant GitHub topics (keywords) for this repository:
          
          Repository name: #{context[:name]}
          Language: #{context[:language]}
          Framework: #{context[:framework]}
          Purpose: #{context[:purpose]}
          
          Return topics as comma-separated lowercase words (e.g., javascript, react, api, nodejs).
          No quotes, no explanations, just the comma-separated list.
        PROMPT
      end

      def build_readme_prompt(context)
        title = context[:name].split(/[-_]/).map(&:capitalize).join(" ")
        
        <<~PROMPT
          Generate a comprehensive README.md for a GitHub repository with these details:
          
          Repository name: #{context[:name]} (Title: #{title})
          Language: #{context[:language]}
          Framework: #{context[:framework]}
          Purpose: #{context[:purpose]}
          
          Include these sections:
          - Title and brief description
          - Features (3-5 bullet points)
          - Installation instructions (language-specific)
          - Usage examples with code blocks
          - Contributing guidelines
          - License (MIT)
          
          Use proper Markdown formatting. Be concise and professional.
          Return only the README content, no extra commentary.
        PROMPT
      end

      def clean_response(text)
        return "" if text.nil? || text.empty?
        
        # Remove common markdown artifacts
        text.gsub(/^```\w*\n/, "")
            .gsub(/\n```$/, "")
            .strip
      end

      def parse_topics(text)
        return [] if text.nil? || text.empty?
        
        # Split by commas and clean up
        topics = text.split(",").map(&:strip).map(&:downcase)
        
        # Remove duplicates and limit to 8
        topics.uniq.first(8)
      end
    end
  end
end
