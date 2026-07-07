# typed: true
# frozen_string_literal: true

#
# Formula/pkg-defender.rb
#
# Homebrew formula for pkg-defender.
# Tap: divisionseven/homebrew-pkg-defender
# Install with:
#   brew tap divisionseven/pkg-defender
#   brew install pkg-defender
#
# SHA256 values are placeholders; the release workflow auto-replaces them.
#

class PkgDefender < Formula
  desc "Stop supply chain attacks before they reach your machine or CI pipeline"
  homepage "https://github.com/divisionseven/pkg-defender"
  version "1.0.4"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/divisionseven/pkg-defender/releases/download/v1.0.4/pkgd-darwin-arm64"
      sha256 "118aa7b6fac0060259fcef4226423ad4c19e0a845971cba4af1f4a40374597c7"

      define_method(:install) do
        bin.install "pkgd-darwin-arm64" => "pkgd"
      end
    end

    on_intel do
      url "https://github.com/divisionseven/pkg-defender/releases/download/v1.0.4/pkgd-darwin-amd64"
      sha256 "fbc6f0eb2570370356e9c6c0df5f2e794ba69c30e58dde79c1b2573f5210d7de"

      define_method(:install) do
        bin.install "pkgd-darwin-amd64" => "pkgd"
      end
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/divisionseven/pkg-defender/releases/download/v1.0.4/pkgd-linux-amd64"
      sha256 "0c6e4f11d9e7e0367379d3102b793358e47c7dd6070e69780deb0412cbb57aaf"

      define_method(:install) do
        bin.install "pkgd-linux-amd64" => "pkgd"
      end
    end
  end

  def caveats
    <<~EOS
      After installation, run the setup wizard to configure shell integration:

          pkgd setup

      This interactive wizard will:
      - Install tab completions for your shell
      - Detect installed package managers (brew, npm, pip, etc.)
      - Create a configuration file with default settings
      - Prompt for optional API tokens for threat intelligence feeds
      - Perform an initial threat feed sync

      For transparent command interception (wrapping package manager commands
      like "pip install" and "npm install"), generate shell functions:

          pkgd hooks

      Then add the output to your shell RC file (~/.zshrc, ~/.bashrc, etc.).
      The daemon provides automatic background threat feed sync (recommended):

          pkgd daemon start     # start as background process
          pkgd daemon status    # check daemon status
          pkgd daemon stop      # stop the daemon

      Configuration and data are stored at:
        macOS:   ~/Library/Application Support/pkg-defender/
        Linux:   ~/.config/pkg-defender/  (config)
                 ~/.local/share/pkg-defender/  (data)

      Use `PKGD_CONFIG_PATH` to override the config file path.
      Use `PKGD_DATA_DIR` to override the data directory.

      See https://github.com/divisionseven/pkg-defender for full documentation.
    EOS
  end

  test do
    # Isolate from user's existing config and data — prevents contamination if user
    # has a ~/.config/pkg-defender/pkgd.toml or existing pkg-defender data directory.
    ENV["PKGD_DATA_DIR"] = testpath.to_s
    ENV["PKGD_CONFIG_PATH"] = testpath/"pkgd.toml"

    # 1. Version check — validates binary executes and reports matching version
    assert_match "pkgd version #{version}", shell_output("#{bin}/pkgd --version")

    # 2. Help output — validates subcommand listing and CLI description
    assert_match "PKG-Defender — The supply chain attack defense CLI", shell_output("#{bin}/pkgd --help")

    # 3. Config options — validates CLI can discover and display config schema
    #    This exercises subcommand dispatch (config → options) and the full config
    #    system without requiring any network access or pre-existing data.
    assert_match "cooldown.default_days", shell_output("#{bin}/pkgd config options")

    # 4. Config get — validates argument parsing and single-value retrieval
    #    Verifies the default value is correct (7 days).
    output = shell_output("#{bin}/pkgd config get cooldown.default_days").strip
    assert_equal "7", output

    # 5. Status with JSON — validates DB creation, JSON output, and empty state
    #    This is the most "real" assertion: it creates a SQLite database at
    #    testpath/threats.db and returns a valid JSON status report.
    #    Uses assert_match on raw JSON string to avoid needing `require "json"`.
    assert_match '"total_threats": 0', shell_output("#{bin}/pkgd status --json")
  end
end
