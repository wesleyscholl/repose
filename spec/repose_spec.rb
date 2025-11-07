# frozen_string_literal: true

RSpec.describe Repose do
  it "has a version number" do
    expect(Repose::VERSION).not_to be nil
  end

  it "has a configuration" do
    expect(Repose.config).to be_a(Repose::Config)
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| Repose.configure(&b) }.to yield_with_args(Repose.config)
    end
  end
end