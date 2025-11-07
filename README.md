# Repose 🎯

> **AI-powered GitHub repository creation and management**

Repose (re-compose) is an intelligent CLI tool that uses AI to create GitHub repositories with smart descriptions, relevant topics, comprehensive READMEs, and proper project structure. No more staring at blank repository forms!

## ✨ Features

- **🤖 AI-Generated Content**: Automatically generates descriptions, topics, and READMEs
- **🎯 Smart Context Awareness**: Understands project purpose from name and language
- **🔧 Interactive CLI**: Guided prompts for missing information
- **📝 Professional READMEs**: Creates comprehensive, well-structured documentation
- **🏷️ Intelligent Topics**: Generates relevant tags and topics automatically
- **👁️ Preview Mode**: See generated content before creating repository
- **🔐 Secure Configuration**: Encrypted storage of API keys and tokens

## 🚀 Installation

```bash
gem install repose
```

Or add to your Gemfile:

```ruby
gem 'repose'
```

## ⚙️ Configuration

First, configure your API credentials:

```bash
repose configure
```

You'll need:
- **GitHub Personal Access Token** (with repo permissions)
- **OpenAI API Key** (for AI content generation)

## 🎨 Usage

### Create a Repository

Basic usage:
```bash
repose create my-awesome-project
```

With specific options:
```bash
repose create web-scraper --language ruby --framework rails --private
```

Advanced usage:
```bash
repose create ai-chatbot \
  --language python \
  --framework fastapi \
  --topics ai,chatbot,nlp,api \
  --description "Intelligent chatbot with natural language processing"
```

### Preview Mode

See what will be created without actually creating:
```bash
repose create my-project --dry-run
```

### Interactive Mode

Repose will intelligently prompt for missing information:

```bash
$ repose create awesome-api
🎯 Repose - AI Repository Creator
========================================
Primary programming language: ruby
Framework/Library (optional): Rails  
What will this project do? A REST API for managing user data

📋 Generated Repository Content
----------------------------------------
Name: awesome-api
Description: Rails-based REST API for efficient user data management
Topics: ruby, rails, api, rest, json, web-development

README Preview:
# Awesome API

A Ruby on Rails REST API for efficient user data management...

Create repository? (Y/n)
```

## 🎯 How It Works

1. **Context Gathering**: Analyzes repository name, language, framework, and purpose
2. **AI Generation**: Uses OpenAI GPT-4 to generate intelligent content
3. **GitHub Integration**: Creates repository with generated content via GitHub API
4. **Quality Assurance**: Fallback mechanisms ensure robust content generation

## 🛠️ Configuration Options

The configuration file (`~/.repose.yml`) supports:

```yaml
github_token: "your_github_token"
openai_api_key: "your_openai_key"
default_topics: ["opensource", "ruby"]
default_language: "ruby"
```

## 📚 Examples

### Python Data Science Project
```bash
repose create ml-stock-predictor --language python --framework scikit-learn
```

### React Frontend
```bash
repose create dashboard-ui --language typescript --framework react
```

### Go Microservice
```bash
repose create user-service --language go --framework gin
```

## 🧩 Project Structure

```
repose/
├── lib/
│   └── repose/
│       ├── cli.rb           # Command-line interface
│       ├── github_client.rb # GitHub API integration  
│       ├── ai_generator.rb  # OpenAI content generation
│       ├── config.rb        # Configuration management
│       └── errors.rb        # Error definitions
├── exe/
│   └── repose              # Executable
└── spec/                   # Tests
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run the tests (`bundle exec rspec`)
5. Lint your code (`bundle exec rubocop`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 🧪 Development

```bash
git clone https://github.com/wesleyscholl/repose.git
cd repose
bundle install
bundle exec rspec
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenAI for providing the GPT-4 API
- GitHub for the excellent Octokit library
- The Ruby community for amazing gems that made this possible

---

**Made with ❤️ by [Wesley Scholl](https://github.com/wesleyscholl)**

*Repose: Where repositories compose themselves* ✨