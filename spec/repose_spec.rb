# frozen_string_literal: true

RSpec.describe Repose do
  it "has a version number" do
    expect(Repose::VERSION).not_to be_nil
  end

  it "has a configuration" do
    expect(described_class.config).to be_a(Repose::Config)
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.config)
    end
  end
end
