# frozen_string_literal: true

require "json"

module Repose
  class ProjectFilesGenerator
    def self.generate(language:, framework:, name:)
      files = {}

      case language&.downcase
      when "go", "golang"
        files.merge!(generate_go_files(name))
      when "python"
        files.merge!(generate_python_files(framework))
      when "javascript", "typescript", "node.js", "nodejs"
        files.merge!(generate_javascript_files(name, language))
      when "ruby"
        files.merge!(generate_ruby_files(framework))
      when "rust"
        files.merge!(generate_rust_files(name))
      when "java"
        files.merge!(generate_java_files(name, framework))
      when "c#", "csharp", "dotnet", ".net"
        files.merge!(generate_dotnet_files(name))
      when "php"
        files.merge!(generate_php_files(framework))
      end

      files
    end

    def self.generate_go_files(name)
      module_path = "github.com/user/#{name}"

      {
        "go.mod" => <<~GO_MOD,
          module #{module_path}

          go 1.21

          require (
          \t// Add your dependencies here
          )
        GO_MOD
        ".gitignore" => <<~GITIGNORE
          # Binaries for programs and plugins
          *.exe
          *.exe~
          *.dll
          *.so
          *.dylib

          # Test binary, built with `go test -c`
          *.test

          # Output of the go coverage tool
          *.out

          # Dependency directories
          vendor/

          # Go workspace file
          go.work
        GITIGNORE
      }
    end

    def self.generate_python_files(framework)
      files = {
        "requirements.txt" => <<~REQUIREMENTS,
          # Add your dependencies here
          # Example:
          # requests>=2.31.0
          # flask>=3.0.0
        REQUIREMENTS
        ".gitignore" => <<~GITIGNORE
          # Byte-compiled / optimized / DLL files
          __pycache__/
          *.py[cod]
          *$py.class

          # Virtual environments
          venv/
          env/
          ENV/
          .venv

          # Distribution / packaging
          dist/
          build/
          *.egg-info/

          # IDEs
          .idea/
          .vscode/
          *.swp
          *.swo

          # Testing
          .pytest_cache/
          .coverage
          htmlcov/
        GITIGNORE
      }

      if framework&.downcase&.include?("django")
        files["requirements.txt"] = "django>=4.2.0\ndjango-environ>=0.11.0\npsycopg2-binary>=2.9.0\n"
      elsif framework&.downcase&.include?("flask")
        files["requirements.txt"] = "flask>=3.0.0\nflask-cors>=4.0.0\npython-dotenv>=1.0.0\n"
      elsif framework&.downcase&.include?("fastapi")
        files["requirements.txt"] = "fastapi>=0.104.0\nuvicorn[standard]>=0.24.0\npydantic>=2.5.0\n"
      end

      files
    end

    def self.generate_javascript_files(name, language)
      is_typescript = language&.downcase&.include?("typescript")

      package_json = {
        name: name,
        version: "1.0.0",
        description: "",
        main: is_typescript ? "dist/index.js" : "index.js",
        scripts: {
          test: 'echo "Error: no test specified" && exit 1'
        },
        keywords: [],
        author: "",
        license: "MIT"
      }

      if is_typescript
        package_json[:scripts][:build] = "tsc"
        package_json[:scripts][:dev] = "ts-node src/index.ts"
        package_json[:devDependencies] = {
          typescript: "^5.3.0",
          "@types/node": "^20.10.0",
          "ts-node": "^10.9.0"
        }
      end

      files = {
        "package.json" => JSON.pretty_generate(package_json),
        ".gitignore" => <<~GITIGNORE
          # Dependencies
          node_modules/

          # Production
          dist/
          build/

          # Environment
          .env
          .env.local

          # Logs
          logs/
          *.log
          npm-debug.log*

          # IDEs
          .idea/
          .vscode/
          *.swp

          # OS
          .DS_Store
          Thumbs.db
        GITIGNORE
      }

      if is_typescript
        files["tsconfig.json"] = JSON.pretty_generate({
                                                        compilerOptions: {
                                                          target: "ES2020",
                                                          module: "commonjs",
                                                          lib: ["ES2020"],
                                                          outDir: "./dist",
                                                          rootDir: "./src",
                                                          strict: true,
                                                          esModuleInterop: true,
                                                          skipLibCheck: true,
                                                          forceConsistentCasingInFileNames: true
                                                        },
                                                        include: ["src/**/*"],
                                                        exclude: ["node_modules"]
                                                      }, indent: "  ")
      end

      files
    end

    def self.generate_ruby_files(framework)
      gemfile = if framework&.downcase&.include?("rails")
                  <<~GEMFILE
                    source 'https://rubygems.org'
                    ruby '~> 3.2'

                    gem 'rails', '~> 7.1'
                    gem 'pg', '~> 1.5'
                    gem 'puma', '~> 6.0'

                    group :development, :test do
                      gem 'rspec-rails'
                      gem 'rubocop'
                    end
                  GEMFILE
                elsif framework&.downcase&.include?("sinatra")
                  <<~GEMFILE
                    source 'https://rubygems.org'
                    ruby '~> 3.2'

                    gem 'sinatra', '~> 3.1'
                    gem 'sinatra-contrib', '~> 3.1'
                    gem 'puma', '~> 6.0'

                    group :development, :test do
                      gem 'rspec'
                      gem 'rack-test'
                      gem 'rubocop'
                    end
                  GEMFILE
                else
                  <<~GEMFILE
                    source 'https://rubygems.org'
                    ruby '~> 3.2'

                    # Add your dependencies here

                    group :development, :test do
                      gem 'rspec'
                      gem 'rubocop'
                    end
                  GEMFILE
                end

      {
        "Gemfile" => gemfile,
        ".gitignore" => <<~GITIGNORE
          # Bundler
          .bundle/
          vendor/bundle/

          # Logs
          log/*.log
          tmp/

          # Database
          *.sqlite3
          *.db

          # Environment
          .env
          .env.local

          # IDEs
          .idea/
          .vscode/
          *.swp
        GITIGNORE
      }
    end

    def self.generate_rust_files(name)
      {
        "Cargo.toml" => <<~CARGO_TOML,
          [package]
          name = "#{name.tr("-", "_")}"
          version = "0.1.0"
          edition = "2021"

          [dependencies]
          # Add your dependencies here
        CARGO_TOML
        ".gitignore" => <<~GITIGNORE
          # Build output
          /target/
          Cargo.lock

          # IDE
          .idea/
          .vscode/
          *.swp
        GITIGNORE
      }
    end

    def self.generate_java_files(name, framework)
      files = {
        ".gitignore" => <<~GITIGNORE
          # Compiled class files
          *.class
          target/
          out/

          # Package files
          *.jar
          *.war
          *.ear

          # IDE
          .idea/
          .vscode/
          *.iml
          .project
          .classpath
          .settings/

          # Build tools
          .gradle/
          build/
        GITIGNORE
      }

      if framework&.downcase&.include?("spring")
        files["pom.xml"] = <<~POM_XML
          <?xml version="1.0" encoding="UTF-8"?>
          <project xmlns="http://maven.apache.org/POM/4.0.0"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                   http://maven.apache.org/xsd/maven-4.0.0.xsd">
              <modelVersion>4.0.0</modelVersion>
          #{"    "}
              <groupId>com.example</groupId>
              <artifactId>#{name}</artifactId>
              <version>0.1.0</version>
          #{"    "}
              <parent>
                  <groupId>org.springframework.boot</groupId>
                  <artifactId>spring-boot-starter-parent</artifactId>
                  <version>3.2.0</version>
              </parent>
          #{"    "}
              <dependencies>
                  <dependency>
                      <groupId>org.springframework.boot</groupId>
                      <artifactId>spring-boot-starter-web</artifactId>
                  </dependency>
              </dependencies>
          </project>
        POM_XML
      end

      files
    end

    def self.generate_dotnet_files(_name)
      {
        ".gitignore" => <<~GITIGNORE
          # Build output
          bin/
          obj/

          # User-specific files
          *.suo
          *.user
          *.userosscache
          *.sln.docstates

          # NuGet
          *.nupkg
          *.snupkg
          packages/

          # IDE
          .vs/
          .vscode/
        GITIGNORE
      }
    end

    def self.generate_php_files(framework)
      composer_json = {
        name: "vendor/package",
        description: "",
        type: "project",
        require: {
          php: ">=8.1"
        },
        "require-dev": {
          "phpunit/phpunit": "^10.0"
        },
        autoload: {
          "psr-4": {
            "App\\": "src/"
          }
        }
      }

      if framework&.downcase&.include?("laravel")
        composer_json[:require]["laravel/framework"] = "^10.0"
      elsif framework&.downcase&.include?("symfony")
        composer_json[:require]["symfony/framework-bundle"] = "^6.4"
      end

      {
        "composer.json" => JSON.pretty_generate(composer_json, indent: "    "),
        ".gitignore" => <<~GITIGNORE
          # Dependencies
          /vendor/

          # Environment
          .env
          .env.local

          # Logs
          *.log

          # IDE
          .idea/
          .vscode/
          *.swp
        GITIGNORE
      }
    end
  end
end
