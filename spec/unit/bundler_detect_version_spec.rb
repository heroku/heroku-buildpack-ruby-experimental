# frozen_string_literal: true

require_relative "../spec_helper.rb"

module HerokuBuildpackRuby
  RSpec.describe "bundler detect version" do
    it "detects major bundler version 2" do
      Dir.mktmpdir do |dir|
        lockfile_path = Pathname(dir).join("Gemfile.lock")
        lockfile_path.write <<~EOM
          BUNDLED WITH
             2.1.4
        EOM

        detect = BundlerDetectVersion.new(
          lockfile_path: lockfile_path
        ).call

        expect(detect.version).to eq(BundlerDetectVersion::BUNDLER_VERSIONS["2"])
      end
    end

    it "detects major bundler version 1" do
      Dir.mktmpdir do |dir|
        lockfile_path = Pathname(dir).join("Gemfile.lock")
        lockfile_path.write <<~EOM
          BUNDLED WITH
             1.1.4
        EOM

        detect = BundlerDetectVersion.new(
          lockfile_path: lockfile_path
        ).call

        expect(detect.version).to eq(BundlerDetectVersion::BUNDLER_VERSIONS["1"])
      end
    end

    it "detects default" do
      Dir.mktmpdir do |dir|
        lockfile_path = Pathname(dir).join("Gemfile.lock")
        lockfile_path.write <<~EOM
          BUNDLED WITH
             1.1.4
        EOM

        detect = BundlerDetectVersion.new(
          lockfile_path: lockfile_path
        ).call

        expect(detect.version).to eq(BundlerDetectVersion::BUNDLER_VERSIONS["1"])
      end
    end

    it "detects version default when not specified" do
      Dir.mktmpdir do |dir|
        lockfile_path = Pathname(dir).join("Gemfile.lock")
        lockfile_path.write ""

        detect = BundlerDetectVersion.new(
          lockfile_path: lockfile_path
        ).call

        expect(detect.version).to eq(BundlerDetectVersion::BUNDLER_VERSIONS[nil])
      end
    end
  end
end
