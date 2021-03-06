# frozen_string_literal: true

require_relative "../spec_helper.rb"

module HerokuBuildpackRuby
  RSpec.describe "assets_precompile" do
    it "streams the contents of the rake task to the output" do
      Hatchet::Runner.new("default_ruby").in_directory do
        dir = Pathname(Dir.pwd)
        dir.join("Rakefile").write <<~EOM
          task "assets:precompile" do
            puts "woop woop precompile worked"
          end

          task "assets:clean" do
            puts "woop woop clean worked"
          end
        EOM

        user_comms = UserComms::Null.new
        Bundler.with_original_env do
          AssetsPrecompile.new(
            has_assets_precompile: true,
            has_assets_clean: true,
            user_comms: user_comms,
            app_dir: dir,
          ).call
        end

        expect(user_comms.to_string).to include("rake assets:precompile")
        expect(user_comms.to_string).to include("woop woop precompile worked")
        expect(user_comms.to_string).to include("woop woop clean worked")
      end
    end

    it "skips asset compilation when manifest is found" do
      Dir.mktmpdir do |dir|
        dir = Pathname(dir)
        public_dir = dir.join("public/assets").tap(&:mkpath)

        FileUtils.touch(public_dir.join(".sprockets-manifest-asdf.json"))

        user_comms = UserComms::Null.new
        AssetsPrecompile.new(
          has_assets_precompile: false,
          has_assets_clean: true,
          user_comms: user_comms,
          app_dir: dir,
        ).call

        expect(user_comms.to_string).to include("asset manifest found")
      end
    end

    it "skips asset compilation when task is not found" do
      Dir.mktmpdir do |dir|
        dir = Pathname(dir)
        rake = Object.new
        def rake.detect?(value); return false if value == "assets:precompile"; end

        user_comms = UserComms::Null.new
        AssetsPrecompile.new(
          has_assets_precompile: false,
          has_assets_clean: true,
          user_comms: user_comms,
          app_dir: dir,
        ).call

        expect(user_comms.to_string).to include("Asset compilation skipped")
      end
    end
  end
end
