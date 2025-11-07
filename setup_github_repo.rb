#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple script to create the GitHub repository for repose
# This demonstrates the kind of automation that repose will provide

require 'net/http'
require 'json'
require 'uri'

def create_github_repo
  puts "🚀 Creating GitHub repository for Repose..."
  
  # Check if gh CLI is available
  if system('which gh > /dev/null 2>&1')
    puts "✅ Found GitHub CLI, creating repository..."
    
    repo_data = {
      name: "repose",
      description: "AI-powered GitHub repository creation and management tool written in Ruby",
      topics: ["ruby", "cli", "github", "automation", "ai", "repository-management", "thor", "gem"],
      private: false
    }
    
    # Create repository using GitHub CLI
    cmd = [
      "gh", "repo", "create", repo_data[:name],
      "--description", repo_data[:description],
      "--public",
      "--source", ".",
      "--remote", "origin",
      "--push"
    ]
    
    success = system(*cmd)
    
    if success
      puts "✅ Repository created successfully!"
      puts "🔗 Repository URL: https://github.com/wesleyscholl/repose"
      
      # Add topics using GitHub API
      puts "🏷️  Adding topics..."
      topic_cmd = [
        "gh", "api", "-X", "PUT",
        "/repos/wesleyscholl/repose/topics",
        "-f", "names=#{repo_data[:topics].join(',')}"
      ]
      
      if system(*topic_cmd)
        puts "✅ Topics added successfully!"
      else
        puts "⚠️  Topics may not have been added, but repository was created"
      end
      
      puts "\n🎉 Next steps:"
      puts "1. Visit: https://github.com/wesleyscholl/repose"
      puts "2. Set up GitHub Actions for CI/CD"
      puts "3. Configure RubyGems publishing"
      puts "4. Add OpenAI integration when ready"
      
    else
      puts "❌ Failed to create repository"
      exit 1
    end
  else
    puts "❌ GitHub CLI not found. Please install it first:"
    puts "   brew install gh"
    puts "   gh auth login"
    exit 1
  end
end

def main
  puts "🎯 Repose Repository Setup"
  puts "=" * 40
  
  # Check if we're in a git repository
  unless Dir.exist?('.git')
    puts "❌ Not in a git repository. Please run 'git init' first."
    exit 1
  end
  
  # Check if there are commits
  if `git rev-list --count HEAD 2>/dev/null`.strip == "0"
    puts "❌ No commits found. Please make an initial commit first."
    exit 1
  end
  
  create_github_repo
end

main if __FILE__ == $PROGRAM_NAME