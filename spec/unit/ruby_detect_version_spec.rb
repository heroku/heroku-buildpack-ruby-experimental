# frozen_string_literal: true

require_relative "../spec_helper.rb"

module HerokuBuildpackRuby
  RSpec.describe "detect ruby version" do
    it "works with jruby" do
      Dir.mktmpdir do |dir|
        dir = Pathname(dir)
        dir.join("Gemfile").write <<~EOM
          source "https://rubygems.org"

          ruby '2.5.7', engine: 'jruby', engine_version: '9.2.13.0'
        EOM
        dir.join("Gemfile.lock").write <<~EOM
          GEM
            remote: https://rubygems.org/
            specs:

          PLATFORMS
            java

          RUBY VERSION
             ruby 2.5.7p001 (jruby 9.2.13.0)

          DEPENDENCIES
        EOM

        ruby_version = RubyDetectVersion.new(
          buildpack_ruby_path: which_ruby,
          bundler_path: which_bundle,
          gemfile_dir: dir
        )
        ruby_version.call
        expect(ruby_version.version.to_s).to eq("2.5.7-jruby-9.2.13.0")
      end
    end

    it "matches on lockfile" do
      Dir.mktmpdir do |dir|
        lockfile = Pathname(dir).join("Gemfile.lock")
        lockfile.write <<~EOM
          PLATFORMS
            ruby

          DEPENDENCIES
            heroku_hatchet
            parallel_split_test
            rspec-retry

          RUBY VERSION
             ruby 2.7.2p137

          BUNDLED WITH
             2.1.4
        EOM
        ruby_version = RubyDetectVersion.new(
          buildpack_ruby_path: which_ruby,
          bundler_path: which_bundle,
          gemfile_dir: dir
        )
        ruby_version.call
        expect(ruby_version.version.to_s).to eq("2.7.2")
      end
    end

    it "detects from Gemfile" do
      Dir.mktmpdir do |dir|

        File.open("#{dir}/Gemfile", "w+") do |f|
          f.write "ruby '2.7.6'"
        end
        FileUtils.touch("#{dir}/Gemfile.lock")

        ruby_version = RubyDetectVersion.new(
          buildpack_ruby_path: which_ruby,
          bundler_path: which_bundle,
          gemfile_dir: dir
        )

        # We need a clean environment, we don't want to run bundler inside of another bundler
        Bundler.with_unbundled_env do
          ruby_version.call
          expect(ruby_version.version.to_s).to eq("2.7.6")
        end
      end
    end

    it "defaults if empty" do
      Dir.mktmpdir do |dir|

        FileUtils.touch("#{dir}/Gemfile.lock")
        FileUtils.touch("#{dir}/Gemfile")

        user_comms = UserComms::Null.new
        ruby_version = RubyDetectVersion.new(
          user_comms: user_comms,
          gemfile_dir: dir,
          bundler_path: which_bundle,
          buildpack_ruby_path: which_ruby,
        )

        # We need a clean environment, we don't want to run bundler inside of another bundler
        Bundler.with_unbundled_env do
          ruby_version.call
          expect(ruby_version.version.to_s).to eq(RubyDetectVersion::DEFAULT)
        end

        user_comms.close
        expect(user_comms.io.string).to include("You have not declared a Ruby version in your Gemfile")
      end
    end

    it "has a sticky default" do
      Dir.mktmpdir do |dir|

        FileUtils.touch("#{dir}/Gemfile.lock")
        FileUtils.touch("#{dir}/Gemfile")

        metadata = Metadata::Null.new
        ruby_version = RubyDetectVersion.new(
          metadata: metadata,
          gemfile_dir: dir,
          bundler_path: which_bundle,
          default_version: "2.7.1",
          buildpack_ruby_path: which_ruby,
        )

        # We need a clean environment, we don't want to run bundler inside of another bundler
        Bundler.with_unbundled_env do
          ruby_version.call
          expect(ruby_version.version.to_s).to eq("2.7.1")
          expect(metadata.layer(:ruby).get(:default_version)).to eq("2.7.1")
        end

        # It should be stickey
        ruby_version = RubyDetectVersion.new(
          metadata: metadata,
          gemfile_dir: dir,
          bundler_path: which_bundle,
          default_version: "2.2.2",
          buildpack_ruby_path: which_ruby,
        )

        Bundler.with_unbundled_env do
          ruby_version.call
          expect(ruby_version.version.to_s).to eq("2.7.1")
        end
      end
    end
  end
end
