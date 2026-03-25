# frozen_string_literal: true

RSpec.describe Repose::ProjectFilesGenerator do
  describe ".generate_konjo_files" do
    subject(:konjo_files) { described_class.generate_konjo_files }

    it "includes AGENTS.md" do
      expect(konjo_files).to have_key("AGENTS.md")
    end

    it "includes CLAUDE.md" do
      expect(konjo_files).to have_key("CLAUDE.md")
    end

    it "includes .github/copilot-instructions.md" do
      expect(konjo_files).to have_key(".github/copilot-instructions.md")
    end

    it "AGENTS.md contains Konjo content" do
      expect(konjo_files["AGENTS.md"]).to include("Konjo AI Project Conventions")
    end

    it "CLAUDE.md contains Konjo content" do
      expect(konjo_files["CLAUDE.md"]).to include("Konjo AI Project Conventions")
    end

    it "copilot-instructions.md contains Konjo content" do
      expect(konjo_files[".github/copilot-instructions.md"]).to include("Konjo AI Project Conventions")
    end
  end

  describe ".generate" do
    it "always includes AGENTS.md regardless of language" do
      files = described_class.generate(language: nil, framework: nil, name: "test")
      expect(files).to have_key("AGENTS.md")
    end

    it "always includes CLAUDE.md regardless of language" do
      files = described_class.generate(language: nil, framework: nil, name: "test")
      expect(files).to have_key("CLAUDE.md")
    end

    it "always includes .github/copilot-instructions.md regardless of language" do
      files = described_class.generate(language: nil, framework: nil, name: "test")
      expect(files).to have_key(".github/copilot-instructions.md")
    end

    it "includes konjo files alongside go project files" do
      files = described_class.generate(language: "go", framework: nil, name: "my-service")
      expect(files).to have_key("AGENTS.md")
      expect(files).to have_key("CLAUDE.md")
      expect(files).to have_key(".github/copilot-instructions.md")
      expect(files).to have_key("go.mod")
    end

    it "includes konjo files alongside python project files" do
      files = described_class.generate(language: "python", framework: nil, name: "my-app")
      expect(files).to have_key("AGENTS.md")
      expect(files).to have_key("CLAUDE.md")
      expect(files).to have_key(".github/copilot-instructions.md")
      expect(files).to have_key("requirements.txt")
    end

    it "includes konjo files alongside ruby project files" do
      files = described_class.generate(language: "ruby", framework: nil, name: "my-gem")
      expect(files).to have_key("AGENTS.md")
      expect(files).to have_key("CLAUDE.md")
      expect(files).to have_key(".github/copilot-instructions.md")
      expect(files).to have_key("Gemfile")
    end

    it "includes konjo files alongside rust project files" do
      files = described_class.generate(language: "rust", framework: nil, name: "my-crate")
      expect(files).to have_key("AGENTS.md")
      expect(files).to have_key("CLAUDE.md")
      expect(files).to have_key(".github/copilot-instructions.md")
      expect(files).to have_key("Cargo.toml")
    end

    it "includes konjo files alongside javascript project files" do
      files = described_class.generate(language: "javascript", framework: nil, name: "my-app")
      expect(files).to have_key("AGENTS.md")
      expect(files).to have_key("CLAUDE.md")
      expect(files).to have_key(".github/copilot-instructions.md")
      expect(files).to have_key("package.json")
    end
  end
end
