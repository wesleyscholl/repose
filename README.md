# Repose 🎯

> **AI-powered GitHub repository creation and management tool**

[![Gem Version](https://badge.fury.io/rb/repose.svg)](https://badge.fury.io/rb/repose)
[![CI](https://github.com/wesleyscholl/repose/actions/workflows/ci.yml/badge.svg)](https://github.com/wesleyscholl/repose/actions/workflows/ci.yml)
[![Test Coverage](https://img.shields.io/badge/coverage-98.39%25-brightgreen.svg)](https://github.com/wesleyscholl/repose)
[![Ruby Version](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://ruby-lang.org)

Repose (re-compose) is an intelligent CLI tool that uses AI to create GitHub repositories with smart descriptions, relevant topics, comprehensive READMEs, and proper project structure. No more staring at blank repository forms!

## ✨ Features

- **🤖 AI-Generated Content**: Automatically generates descriptions, topics, and READMEs using intelligent patterns
- **🎯 Smart Context Awareness**: Understands project purpose from name, language, and framework
- **🔧 Interactive CLI**: Guided prompts for missing information with beautiful UI
- **📝 Professional READMEs**: Creates comprehensive, well-structured documentation
- **🏷️ Intelligent Topics**: Generates relevant tags and topics automatically
- **👁️ Preview Mode**: See generated content before creating repository
- **🔐 Secure Configuration**: Encrypted storage of API keys and tokens
- **⚡ Multi-Language Support**: Built-in support for 10+ programming languages
- **🎨 Framework Intelligence**: Recognizes and suggests popular frameworks
- **🧪 98.39% Test Coverage**: Production-ready with comprehensive testing

## 🚀 Quick Start

### Installation

```bash
gem install repose
```

### Setup

Configure your credentials (one-time setup):

```bash
repose configure
```

You'll need:
- **GitHub Personal Access Token** (with repo permissions)
- **OpenAI API Key** (optional, for enhanced AI features)

### Create Your First Repository

```bash
repose create my-awesome-project
```

That's it! Repose will intelligently guide you through the process.

## 🎨 Usage Examples

### Basic Usage
```bash
# Interactive mode - Repose guides you
repose create my-project

# Quick creation with language
repose create web-scraper --language ruby

# Full specification
repose create api-server --language go --framework gin --private
```

### Advanced Usage
```bash
# Preview before creating
repose create ai-chatbot --language python --framework fastapi --dry-run

# Custom description and topics
repose create data-processor \
  --language python \
  --description "High-performance data processing pipeline" \
  --topics ml,data,etl,python

# Framework-specific project
repose create blog-api --language ruby --framework rails --private
```

### Interactive Experience
```bash
$ repose create awesome-api
🎯 Repose - AI Repository Creator
========================================
Primary programming language: ruby
Framework/Library: Rails  
What will this project do? A REST API for user management

📋 Generated Repository Content
----------------------------------------
Name: awesome-api
Description: A Ruby Rails project for user management
Topics: ruby, rails, api, web, rest

README Preview:
# Awesome Api

A Ruby Rails project for user management with comprehensive
API endpoints and authentication.

## Features
- User authentication and authorization
- RESTful API design
- Database integration
- Comprehensive test coverage

Create repository? (Y/n) y
✅ Repository created successfully!
🔗 https://github.com/yourusername/awesome-api
```

## 🛠️ Configuration

### Initial Setup
```bash
repose configure
```

### Configuration File
Located at `~/.repose.yml`:

```yaml
github_token: "your_github_token"
openai_api_key: "your_openai_key"  # Optional
default_topics: ["opensource", "ruby"]
default_language: "ruby"
```

### Environment Variables
```bash
export GITHUB_TOKEN="your_token"
export OPENAI_API_KEY="your_key"  # Optional
```

## 🌍 Supported Languages & Frameworks

| Language | Frameworks |
|----------|------------|
| **Ruby** | Rails, Sinatra, Hanami, Roda |
| **JavaScript/TypeScript** | React, Vue, Express, Next.js, Nuxt, Angular |
| **Python** | Django, Flask, FastAPI, Streamlit |
| **Go** | Gin, Echo, Fiber, Chi |
| **Java** | Spring Boot, Quarkus, Micronaut |
| **Rust** | Actix, Axum, Warp, Rocket |
| **Swift** | Vapor, Perfect, Kitura |
| **PHP** | Laravel, Symfony, CodeIgniter |
| **Kotlin** | Spring Boot, Ktor |
| **And more...** | Extensible architecture |

## 📚 Command Reference

### `repose create [NAME]`
Create a new repository with AI assistance.

**Options:**
- `--language LANG` - Primary programming language
- `--framework FRAMEWORK` - Framework or library to use  
- `--description TEXT` - Custom description override
- `--private` - Create private repository (default: public)
- `--topics TOPIC1,TOPIC2` - Custom topics/tags
- `--dry-run` - Preview without creating
- `--template URL` - Use repository template

**Examples:**
```bash
repose create web-app --language typescript --framework react
repose create microservice --language go --private --dry-run
repose create ml-model --language python --topics ml,ai,data-science
```

### `repose configure`
Setup or update configuration settings.

**Interactive prompts for:**
- GitHub Personal Access Token
- OpenAI API Key (optional)
- Default topics
- Default language

### `repose version`
Display version information.

## 🏗️ Project Structure

```
repose/
├── lib/
│   └── repose/
│       ├── cli.rb           # Command-line interface
│       ├── github_client.rb # GitHub API integration  
│       ├── ai_generator.rb  # Content generation
│       ├── config.rb        # Configuration management
│       ├── errors.rb        # Error definitions
│       └── version.rb       # Version information
├── exe/
│   └── repose              # Executable
├── spec/                   # Comprehensive test suite
│   ├── repose/            # Unit tests
│   ├── integration_spec.rb # Integration tests
│   └── spec_helper.rb     # Test configuration
└── .github/
    └── workflows/
        └── ci.yml         # GitHub Actions CI
```

## 🧪 Development & Testing

### Setup Development Environment
```bash
git clone https://github.com/wesleyscholl/repose.git
cd repose
bundle install
```

### Run Tests
```bash
# Run all tests
bundle exec rspec

# Run with coverage
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/repose/cli_spec.rb

# Run linting
bundle exec rubocop
```

### Test Coverage
Current test coverage: **98.39%** (183/186 lines)

- **Unit Tests**: Individual class and method testing
- **Integration Tests**: End-to-end workflow validation  
- **Error Handling Tests**: Comprehensive error scenarios
- **Mock Tests**: External API interaction testing
- **Configuration Tests**: Secure file handling

### Development Tasks
```bash
# Install gem locally
rake install

# Run console with repose loaded
rake console

# Build and test
rake default  # Runs tests + rubocop

# Release (maintainers only)
rake release
```

## 🔒 Security & Privacy

### Data Handling
- **Local Storage**: API keys stored locally with secure permissions (600)
- **No Data Collection**: No telemetry or usage tracking
- **API Communication**: Direct communication with GitHub/OpenAI APIs
- **Input Sanitization**: All user inputs validated and sanitized

### API Key Security
```bash
# Configuration file permissions
chmod 600 ~/.repose.yml

# Environment variable approach (more secure)
export GITHUB_TOKEN="your_token"
export OPENAI_API_KEY="your_key"
```

### Required Permissions
- **GitHub Token**: `repo` scope for repository creation
- **OpenAI Key**: Standard API access (optional)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with tests
4. Ensure tests pass (`bundle exec rspec`)
5. Lint your code (`bundle exec rubocop`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Quality Standards
- **98%+ Test Coverage**: All new features must include comprehensive tests
- **RuboCop Compliance**: Code must pass all linting checks
- **Documentation**: Public methods and complex logic must be documented
- **Performance**: Consider performance implications of changes

## 📊 Metrics & Quality

| Metric | Value |
|--------|-------|
| Test Coverage | 98.39% |
| Test Suite | 123 examples |
| Ruby Compatibility | 3.0+ |
| Dependencies | 8 runtime |
| Code Quality | RuboCop compliant |
| Documentation | Comprehensive |

## 🐛 Troubleshooting

### Common Issues

**Q: "GitHub API error: Bad credentials"**
A: Check your GitHub token has `repo` permissions and is correctly configured.

**Q: "Command not found: repose"**  
A: Ensure gem is installed: `gem install repose` and gem bin path is in $PATH.

**Q: "YAML parsing error"**
A: Check `~/.repose.yml` syntax. Delete file and run `repose configure` to recreate.

**Q: "Repository already exists"**
A: Choose a different repository name or check existing repositories.

### Debug Mode
```bash
# Enable verbose output
REPOSE_DEBUG=1 repose create my-project

# Check configuration
repose configure --show
```

### Getting Help
- 📖 [Documentation](https://github.com/wesleyscholl/repose/wiki)
- 🐛 [Issues](https://github.com/wesleyscholl/repose/issues)
- 💬 [Discussions](https://github.com/wesleyscholl/repose/discussions)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **GitHub** for the excellent Octokit library and API
- **Ruby Community** for amazing gems that made this possible
- **TTY Toolkit** for beautiful CLI components
- **RSpec Team** for comprehensive testing framework
- **Contributors** who help improve Repose

## 🏷️ Version History

- **v1.0.0** (2025-11-07): Production release with 98.39% test coverage
- **v0.1.0** (2024-11-07): Initial release with core functionality

---

<div align="center">

**Made with ❤️ by [Wesley Scholl](https://github.com/wesleyscholl)**

*Repose: Where repositories compose themselves* ✨

[Install](https://rubygems.org/gems/repose) • [Documentation](https://github.com/wesleyscholl/repose/wiki) • [GitHub](https://github.com/wesleyscholl/repose) • [Issues](https://github.com/wesleyscholl/repose/issues)

</div>