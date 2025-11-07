# frozen_string_literal: true

RSpec.describe Repose::Errors do
  describe "Error class hierarchy" do
    it "defines base Error class" do
      expect(described_class::Error).to be < StandardError
    end

    it "defines ConfigError as subclass of Error" do
      expect(described_class::ConfigError).to be < described_class::Error
    end

    it "defines GitHubError as subclass of Error" do
      expect(described_class::GitHubError).to be < described_class::Error
    end

    it "defines AIError as subclass of Error" do
      expect(described_class::AIError).to be < described_class::Error
    end

    it "defines ValidationError as subclass of Error" do
      expect(described_class::ValidationError).to be < described_class::Error
    end
  end

  describe "Error instances" do
    describe "Error" do
      let(:error) { described_class::Error.new("Base error message") }

      it "can be instantiated with a message" do
        expect(error.message).to eq("Base error message")
      end

      it "can be raised and rescued" do
        expect {
          raise error
        }.to raise_error(described_class::Error, "Base error message")
      end
    end

    describe "ConfigError" do
      let(:error) { described_class::ConfigError.new("Configuration is invalid") }

      it "can be instantiated with a message" do
        expect(error.message).to eq("Configuration is invalid")
      end

      it "can be raised and rescued as ConfigError" do
        expect {
          raise error
        }.to raise_error(described_class::ConfigError, "Configuration is invalid")
      end

      it "can be rescued as base Error" do
        expect {
          raise error
        }.to raise_error(described_class::Error)
      end
    end

    describe "GitHubError" do
      let(:error) { described_class::GitHubError.new("GitHub API failed") }

      it "can be instantiated with a message" do
        expect(error.message).to eq("GitHub API failed")
      end

      it "can be raised and rescued as GitHubError" do
        expect {
          raise error
        }.to raise_error(described_class::GitHubError, "GitHub API failed")
      end

      it "can be rescued as base Error" do
        expect {
          raise error
        }.to raise_error(described_class::Error)
      end
    end

    describe "AIError" do
      let(:error) { described_class::AIError.new("AI service unavailable") }

      it "can be instantiated with a message" do
        expect(error.message).to eq("AI service unavailable")
      end

      it "can be raised and rescued as AIError" do
        expect {
          raise error
        }.to raise_error(described_class::AIError, "AI service unavailable")
      end

      it "can be rescued as base Error" do
        expect {
          raise error
        }.to raise_error(described_class::Error)
      end
    end

    describe "ValidationError" do
      let(:error) { described_class::ValidationError.new("Invalid input") }

      it "can be instantiated with a message" do
        expect(error.message).to eq("Invalid input")
      end

      it "can be raised and rescued as ValidationError" do
        expect {
          raise error
        }.to raise_error(described_class::ValidationError, "Invalid input")
      end

      it "can be rescued as base Error" do
        expect {
          raise error
        }.to raise_error(described_class::Error)
      end
    end
  end

  describe "Error handling scenarios" do
    it "allows rescuing specific error types" do
      caught_error = nil

      begin
        raise described_class::ConfigError.new("Test config error")
      rescue described_class::ConfigError => e
        caught_error = e
      end

      expect(caught_error).to be_a(described_class::ConfigError)
      expect(caught_error.message).to eq("Test config error")
    end

    it "allows rescuing all errors with base Error class" do
      errors_caught = []

      [
        described_class::ConfigError.new("Config"),
        described_class::GitHubError.new("GitHub"),
        described_class::AIError.new("AI"),
        described_class::ValidationError.new("Validation")
      ].each do |error|
        begin
          raise error
        rescue described_class::Error => e
          errors_caught << e.class
        end
      end

      expect(errors_caught).to contain_exactly(
        described_class::ConfigError,
        described_class::GitHubError,
        described_class::AIError,
        described_class::ValidationError
      )
    end
  end
end