# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.0] - 2026-03-11

### Added
- **Organization & Namespace Selection**: Choose where to create a new repository
  - Fetches the authenticated user's personal account and all GitHub organization memberships via the API
  - Presents an interactive `Create repository under:` selection prompt when multiple namespaces are available
  - Automatically skips the prompt when the user has no org memberships (personal account only)
  - New `--org ORG` CLI flag to specify the destination directly (bypasses the prompt for scripted use)
  - Gracefully falls back to personal account if namespace fetching fails
  - Preview output now shows `Destination: owner/repo-name` so the target is visible before confirming
- **`GitHubClient#available_namespaces`**: New public method returning personal + org namespaces
- **`GitHubClient#repository_exists?`**: Now accepts an optional `owner` parameter

### Changed
- `GitHubClient#create_repository` accepts a new `owner:` keyword argument; passes `organization:` to the GitHub API when creating under an org

## [1.3.0] - 2025-11-21

### Added
- **License Preview**: License type now displayed in repository preview before creation
- **Language-Specific Project Files**: Automatic generation of boilerplate project files
  - **Go**: `go.mod` and `.gitignore`
  - **Python**: `requirements.txt` and `.gitignore` (with framework-specific dependencies for Django, Flask, FastAPI)
  - **JavaScript/TypeScript**: `package.json`, `tsconfig.json` (TypeScript only), and `.gitignore`
  - **Ruby**: `Gemfile` and `.gitignore` (with framework-specific gems for Rails, Sinatra)
  - **Rust**: `Cargo.toml` and `.gitignore`
  - **Java**: `pom.xml` (Spring Boot projects) and `.gitignore`
  - **.NET**: `.gitignore`
  - **PHP**: `composer.json` (with framework-specific dependencies for Laravel, Symfony) and `.gitignore`
  - All generated files are automatically committed to the new repository

## [1.2.0] - 2025-11-21

### Added
- **20 Topics Generation**: AI now generates up to 20 relevant topics/tags instead of 5-8
  - Enhanced topic generation for comprehensive repository tagging
  - Includes language ecosystem, framework, architecture, deployment, and best practices topics
  - Fallback template generates intelligent topics based on language, framework, and purpose
- **Emoji Support**: Automatic emoji inclusion for visual appeal
  - Repository descriptions now include at least 2 relevant emojis
  - README generation includes emojis in headers and sections
  - Language-specific emojis (💎 Ruby, 🐍 Python, ⚡ JavaScript, etc.)
  - Purpose-based emojis (🌐 API, 📊 Data, 🤖 AI/ML, etc.)
- **License Selection**: Interactive license type selection
  - Support for MIT, Apache 2.0, GPL 3.0, BSD 3-Clause, MPL 2.0, Unlicense
  - Custom/Other license option
  - License passed through to GitHub repository creation
  - README generation includes selected license

### Fixed
- **GitHub Authentication**: Improved GitHub client token handling
  - Now properly reads from `GITHUB_TOKEN` environment variable
  - Better error messages for authentication failures
  - Enhanced error handling for repository creation
  - Support for GitHub API license templates
- **Topic Limits**: Removed artificial 8-topic limit, now supports up to 20
- **Context Propagation**: License now properly propagated through generation pipeline

### Enhanced
- **AI Providers**: Both Gemini and Ollama providers updated
  - Better prompts for emoji and topic generation
  - License-aware README generation
  - Improved formatting and structure
- **Fallback Templates**: Enhanced template-based generation
  - More intelligent topic selection based on project characteristics
  - Language ecosystem topics (npm, bundler, cargo, etc.)
  - Framework-related topics (web, api, microservices, etc.)
  - Purpose-based topic detection (ai, data, testing, security, etc.)

## [1.1.0] - 2025-01-20

### Changed - Gem Renamed
- **Breaking**: Gem renamed from `repose` to `repo-composer` (original name taken on RubyGems)
- Installation: `gem install repo-composer` (was `gem install repose`)
- Command: `repo-composer` (was `repose`)
- All functionality remains identical

### Added - AI Provider Integration 🤖

#### Gemini AI Integration
- **New Provider**: `Repose::AI::GeminiProvider` for Google Gemini AI
  - AI-powered repository descriptions, topics, and README generation
  - Support for multiple models (gemini-1.5-flash default, gemini-1.5-pro)
  - Automatic API key configuration via `GEMINI_API_KEY` environment variable
  - Retry logic with exponential backoff (max 3 retries, 30s timeout)
  - Comprehensive error handling (authentication, rate limiting, timeouts)
  - 56 test cases with full coverage

#### Ollama Local AI Integration
- **New Provider**: `Repose::AI::OllamaProvider` for local AI models
  - Privacy-focused AI generation using locally-hosted models
  - Support for all Ollama models (mistral, llama3, gemma, etc.)
  - Model listing and pulling capabilities
  - Configurable via `OLLAMA_ENDPOINT` and `OLLAMA_MODEL` env vars
  - Connection error handling with setup instructions
  - 56 test cases with full coverage

#### Enhanced AIGenerator
- Auto-detection of available AI providers (Gemini → Ollama → Fallback)
- Explicit provider selection via `provider:` constructor parameter
- `use_ai?` method to check if AI provider is active
- Graceful degradation to template-based generation on errors
- Comprehensive fallback logic for all generation methods
- 13 new test cases for provider integration

#### Error Handling
- Extended error hierarchy with AI-specific exceptions
- `ConfigurationError` for missing/invalid API keys
- `APIError` for general API failures
- `AuthenticationError` for invalid credentials
- `RateLimitError` for API rate limit exceeded

#### Documentation & Demos
- `demo_ai_providers.rb` - Comprehensive demo of all AI features
  - Fallback mode demonstration
  - Gemini integration (when API key available)
  - Ollama integration (when service running)
  - Auto-detection behavior
  - Error handling and graceful degradation
  - Configuration examples

### Changed
- **AIGenerator API**: Now accepts optional `provider:` parameter
  - `:gemini` - Force Gemini provider
  - `:ollama` - Force Ollama provider  
  - `:none`/`false` - Force fallback mode
  - `nil` (default) - Auto-detect best available

### Technical Details
- **Test Coverage**: 96.63% (373/386 lines)
- **New Code**: 455 lines (AI providers)
- **Test Code**: 642 lines (comprehensive suite)
- **Dependencies**: No new gems (uses Net::HTTP)
- **Backward Compatible**: All existing tests passing

### Configuration Examples
```bash
# Gemini
export GEMINI_API_KEY='your-api-key'

# Ollama (optional, defaults shown)
export OLLAMA_ENDPOINT='http://localhost:11434'
export OLLAMA_MODEL='mistral'
```

### Usage Examples
```ruby
# Auto-detect provider
generator = Repose::AIGenerator.new

# Force specific provider
generator = Repose::AIGenerator.new(provider: :gemini)
generator = Repose::AIGenerator.new(provider: :ollama)

# Generate content
result = generator.generate({
  name: "my-project",
  language: "Ruby",
  framework: "Rails",
  purpose: "Web application"
})
```

---

## [1.0.0] - 2025-11-07 🎉

### 🎯 Production Release
First stable production release of Repose - the AI-powered GitHub repository creation tool.

### ✨ Features
- **🤖 AI-Generated Content**: Automatically generates descriptions, topics, and READMEs using GPT-4 patterns
- **🎯 Smart Context Awareness**: Understands project purpose from name, language, and framework
- **🔧 Interactive CLI**: Guided prompts for missing information with intelligent defaults
- **📝 Professional READMEs**: Creates comprehensive, well-structured documentation
- **🏷️ Intelligent Topics**: Generates relevant tags and topics automatically based on project context
- **👁️ Preview Mode**: See generated content before creating repository with `--dry-run`
- **🔐 Secure Configuration**: Encrypted storage of API keys and tokens with proper file permissions
- **⚡ Framework Support**: Built-in support for popular frameworks across multiple languages

### 🛠️ Technical Implementation
- **98.39% Test Coverage**: Comprehensive test suite with unit, integration, and error handling tests
- **Ruby 3.4.7+ Support**: Modern Ruby compatibility with latest language features
- **Robust Error Handling**: Graceful error handling with detailed error messages and recovery options
- **Modular Architecture**: Clean separation of concerns with dedicated classes for each responsibility
- **GitHub API Integration**: Full integration with GitHub API v4 using Octokit
- **Interactive UX**: Beautiful CLI interface using TTY toolkit with spinners, prompts, and colors

### 🌍 Language & Framework Support
- **Ruby**: Rails, Sinatra, Hanami, Roda
- **JavaScript/TypeScript**: React, Vue, Express, Next.js, Nuxt, Angular  
- **Python**: Django, Flask, FastAPI, Streamlit
- **Go**: Gin, Echo, Fiber, Chi
- **Java**: Spring Boot, Quarkus, Micronaut
- **Rust**: Actix, Axum, Warp, Rocket
- **Swift**: Vapor, Perfect, Kitura
- **And more**: Extensible architecture for additional languages

### 🎨 Usage Examples
```bash
# Quick repository creation
repose create my-awesome-project

# With specific options
repose create web-scraper --language ruby --framework rails --private

# Preview before creating
repose create ai-chatbot --language python --framework fastapi --dry-run

# Interactive mode with intelligent prompts
repose create awesome-api  # Repose will guide you through the process
```

### 🔧 Configuration
```bash
# One-time setup
repose configure

# Configure programmatically
repose create my-project --language go --framework gin --topics api,microservice
```

### 📦 Installation
```bash
gem install repose
```

### 🏗️ Architecture
- `Repose::CLI`: Thor-based command-line interface with interactive prompts
- `Repose::AIGenerator`: Intelligent content generation with fallback mechanisms
- `Repose::GitHubClient`: GitHub API integration with error handling
- `Repose::Config`: Secure configuration management with validation
- `Repose::Errors`: Comprehensive error hierarchy for different failure modes

### 🧪 Quality Assurance
- **123 Test Examples**: Comprehensive test coverage across all components
- **Unit Tests**: Individual class and method testing
- **Integration Tests**: End-to-end workflow validation
- **Error Handling Tests**: Comprehensive error scenario coverage
- **Mock & Stub Tests**: External API interaction testing
- **Configuration Tests**: Secure file handling validation

### 📋 Requirements
- Ruby 3.0.0 or higher
- GitHub Personal Access Token (for repository creation)
- OpenAI API Key (for enhanced content generation)

### 🔒 Security
- Secure API key storage with 600 file permissions
- Input validation and sanitization
- Error message sanitization (no sensitive data in logs)
- Secure YAML configuration handling

---

## [0.1.0] - 2024-11-07

### Added
- Initial project structure and core functionality
- Basic CLI interface and GitHub integration
- AI content generation foundation
- Configuration system prototype
- Error handling framework