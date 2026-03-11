#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script showing repose functionality
require_relative "lib/repose"

puts "🎯 Repose Demo - AI Repository Creator"
puts "=" * 50

# Demo the AI generator with sample context
context = {
  name: "awesome-todo-app",
  language: "ruby",
  framework: "rails",
  purpose: "manage daily tasks and todos with a clean interface"
}

puts "📝 Sample Project Context:"
puts "  Name: #{context[:name]}"
puts "  Language: #{context[:language]}"
puts "  Framework: #{context[:framework]}"
puts "  Purpose: #{context[:purpose]}"

puts "\n🤖 Generating content..."

ai_generator = Repose::AIGenerator.new
content = ai_generator.generate(context)

puts "\n📋 Generated Repository Content:"
puts "-" * 40
puts "📛 Description: #{content[:description]}"
puts "🏷️  Topics: #{content[:topics].join(", ")}"

puts "\n📄 Generated README Preview:"
puts "-" * 40
puts "#{content[:readme][0..500]}..."

puts "\n✅ Demo complete! This shows how Repose generates intelligent"
puts "   repository content from minimal input. Once configured with"
puts "   GitHub and OpenAI API keys, it can create real repositories!"

puts "\n🔗 Repository: https://github.com/svc-twm-crs/repose"
puts "🎉 Repose - Where repositories compose themselves!"
