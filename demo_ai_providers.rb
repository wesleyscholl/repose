#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo: Repose AI Provider Integration
# This demonstrates the new Gemini and Ollama AI integration features

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "repose"

def separator
  puts "\n" + ("=" * 80) + "\n"
end

def demo_header(title)
  separator
  puts "  #{title}"
  separator
end

# Sample project context
context = {
  name: "smart-scheduler",
  language: "Python",
  framework: "FastAPI",
  purpose: "intelligent task scheduling and optimization"
}

# ============================================================================
# Demo 1: Fallback Mode (No AI)
# ============================================================================
demo_header("Demo 1: Fallback Mode (Template-Based Generation)")

puts "Creating AIGenerator without AI provider (fallback mode)..."
generator_fallback = Repose::AIGenerator.new(provider: :none)

puts "Provider: #{generator_fallback.provider.inspect}"
puts "Using AI: #{generator_fallback.use_ai?}"

result = generator_fallback.generate(context)

puts "\nGenerated Description:"
puts "  #{result[:description]}"

puts "\nGenerated Topics:"
puts "  #{result[:topics].join(', ')}"

puts "\nGenerated README (first 200 chars):"
puts result[:readme][0..200]
puts "  ..."

# ============================================================================
# Demo 2: Gemini Provider (if API key available)
# ============================================================================
if ENV["GEMINI_API_KEY"]
  demo_header("Demo 2: Gemini AI Provider")

  puts "Creating AIGenerator with Gemini provider..."
  
  begin
    generator_gemini = Repose::AIGenerator.new(provider: :gemini)
    
    if generator_gemini.provider
      puts "Provider: #{generator_gemini.provider.class.name}"
      puts "Using AI: #{generator_gemini.use_ai?}"
      puts "Model: #{generator_gemini.provider.model}"
      puts "Available: #{generator_gemini.provider.available?}"
      
      puts "\nGenerating content with Gemini AI..."
      result_ai = generator_gemini.generate(context)
      
      puts "\nAI-Generated Description:"
      puts "  #{result_ai[:description]}"
      
      puts "\nAI-Generated Topics:"
      puts "  #{result_ai[:topics].join(', ')}"
      
      puts "\nAI-Generated README (first 300 chars):"
      puts result_ai[:readme][0..300]
      puts "  ..."
    else
      puts "Gemini provider not available (check API key)"
    end
    
  rescue Repose::ConfigurationError => e
    puts "Error: #{e.message}"
    puts "Gemini provider requires GEMINI_API_KEY environment variable"
  rescue Repose::APIError => e
    puts "API Error: #{e.message}"
  end
else
  demo_header("Demo 2: Gemini AI Provider (SKIPPED)")
  puts "Set GEMINI_API_KEY environment variable to enable Gemini provider"
  puts "Example: export GEMINI_API_KEY='your-api-key-here'"
end

# ============================================================================
# Demo 3: Ollama Provider (if Ollama is running)
# ============================================================================
demo_header("Demo 3: Ollama Local AI Provider")

puts "Creating AIGenerator with Ollama provider..."

begin
  generator_ollama = Repose::AIGenerator.new(provider: :ollama)
  
  if generator_ollama.provider
    puts "Provider: #{generator_ollama.provider.class.name}"
    puts "Using AI: #{generator_ollama.use_ai?}"
    puts "Endpoint: #{generator_ollama.provider.endpoint}"
    puts "Model: #{generator_ollama.provider.model}"
    puts "Available: #{generator_ollama.provider.available?}"
    
    if generator_ollama.provider.available?
      puts "\nAvailable Models:"
      models = generator_ollama.provider.list_models
      models.first(5).each { |model| puts "  - #{model}" }
      puts "  ... (#{models.length} total)" if models.length > 5
      
      puts "\nGenerating content with Ollama AI..."
      result_ollama = generator_ollama.generate(context)
      
      puts "\nAI-Generated Description:"
      puts "  #{result_ollama[:description]}"
      
      puts "\nAI-Generated Topics:"
      puts "  #{result_ollama[:topics].join(', ')}"
      
      puts "\nAI-Generated README (first 300 chars):"
      puts result_ollama[:readme][0..300]
      puts "  ..."
    else
      puts "\nOllama is not available. Start Ollama server:"
      puts "  brew install ollama"
      puts "  ollama serve"
      puts "  ollama pull mistral"
    end
  else
    puts "Ollama provider not available (service not running)"
    puts "Falling back to template-based generation"
  end
  
rescue Repose::APIError => e
  puts "Error: #{e.message}"
  puts "\nTo use Ollama:"
  puts "  1. Install: brew install ollama"
  puts "  2. Start service: ollama serve"
  puts "  3. Pull a model: ollama pull mistral"
end

# ============================================================================
# Demo 4: Auto-Detection (Gemini > Ollama > Fallback)
# ============================================================================
demo_header("Demo 4: Auto-Detection Mode")

puts "Creating AIGenerator with auto-detection..."
generator_auto = Repose::AIGenerator.new

if generator_auto.provider
  puts "Auto-detected provider: #{generator_auto.provider.class.name}"
  puts "Using AI: #{generator_auto.use_ai?}"
else
  puts "No AI provider available - using fallback mode"
  puts "Using AI: #{generator_auto.use_ai?}"
end

result_auto = generator_auto.generate(context)
puts "\nGenerated Description:"
puts "  #{result_auto[:description]}"

# ============================================================================
# Demo 5: Error Handling (Graceful Fallback)
# ============================================================================
demo_header("Demo 5: Error Handling & Graceful Fallback")

puts "Testing graceful fallback when AI provider fails..."

if ENV["GEMINI_API_KEY"]
  generator_test = Repose::AIGenerator.new(provider: :gemini)
  
  # Simulate API error by using invalid key temporarily
  original_key = ENV["GEMINI_API_KEY"]
  ENV["GEMINI_API_KEY"] = "invalid-key"
  
  puts "Simulating API error..."
  
  # The generator should catch the error and fall back to template generation
  result_fallback = generator_test.generate(context)
  
  puts "Description generated successfully despite API error:"
  puts "  #{result_fallback[:description]}"
  puts "\nThis demonstrates graceful degradation to template-based generation"
  
  # Restore original key
  ENV["GEMINI_API_KEY"] = original_key
else
  puts "Skipped (requires GEMINI_API_KEY)"
end

# ============================================================================
# Demo 6: Custom Configuration
# ============================================================================
demo_header("Demo 6: Custom Configuration")

puts "Ollama with custom endpoint and model:"
custom_ollama = Repose::AIGenerator.new(provider: :ollama)

if custom_ollama.provider
  puts "  Endpoint: #{custom_ollama.provider.endpoint}"
  puts "  Model: #{custom_ollama.provider.model}"
  puts "\nConfigure via environment:"
  puts "  export OLLAMA_ENDPOINT='http://custom:11434'"
  puts "  export OLLAMA_MODEL='gemma'"
else
  puts "  Ollama not available"
end

if ENV["GEMINI_API_KEY"]
  custom_gemini = Repose::AIGenerator.new(provider: :gemini)
  if custom_gemini.provider
    puts "\nGemini configuration:"
    puts "  Model: #{custom_gemini.provider.model}"
    puts "\nSupported models:"
    puts "  - gemini-1.5-flash (default, fast)"
    puts "  - gemini-1.5-pro (advanced)"
  end
end

# ============================================================================
# Summary
# ============================================================================
demo_header("Summary")

puts "Repose AI Integration Features:"
puts ""
puts "  1. Multiple AI Providers:"
puts "     - Gemini (Google's generative AI)"
puts "     - Ollama (Local AI models)"
puts "     - Fallback (Template-based)"
puts ""
puts "  2. Auto-Detection:"
puts "     - Automatically selects best available provider"
puts "     - Priority: Gemini > Ollama > Fallback"
puts ""
puts "  3. Graceful Degradation:"
puts "     - Falls back to templates if AI fails"
puts "     - No disruption to user workflow"
puts ""
puts "  4. Flexible Configuration:"
puts "     - Environment variables"
puts "     - Explicit provider selection"
puts "     - Custom models and endpoints"
puts ""
puts "  5. Comprehensive Error Handling:"
puts "     - API errors caught and handled"
puts "     - Timeouts with retry logic"
puts "     - Rate limiting awareness"
puts ""

separator
puts "Demo complete!"
separator
