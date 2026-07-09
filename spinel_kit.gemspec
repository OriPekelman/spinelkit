require_relative "spinel_kit/version"

Gem::Specification.new do |s|
  s.name        = "spinel_kit"
  s.version     = SpinelKit::VERSION
  s.summary     = "Pure-Ruby Git/Url/Log/Hex shims for Spinel AOT-compiled apps"
  s.description = <<~TEXT.strip
    SpinelKit consolidates the pure-Ruby shims that every Spinel-compiled
    project would otherwise hand-roll and that Spinel (the Ruby->native AOT
    compiler) does not provide: .git/HEAD provenance, URL percent-codec +
    query parsing, a minimal levelled logger, and a hex digit/byte codec.
    (JSON left in 0.3.0: Spinel now bundles `json` as a require-gated stdlib
    package, so consumers use JSON.parse/JSON.generate directly.) Pure Ruby,
    no native extension, no runtime dependencies -- it vendors cleanly via
    bundler-spinel. Pre-alpha.
  TEXT
  s.authors     = ["Ori Pekelman"]
  s.email       = ["ori@pekelman.com"]
  s.license     = "MIT"
  s.homepage    = "https://github.com/OriPekelman/spinelkit"
  s.metadata    = {
    "source_code_uri"       => "https://github.com/OriPekelman/spinelkit",
    "bug_tracker_uri"       => "https://github.com/OriPekelman/spinelkit/issues",
    "documentation_uri"     => "https://github.com/OriPekelman/spinelkit#readme",
    "changelog_uri"         => "https://github.com/OriPekelman/spinelkit/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true",
  }

  # Runtime target is Spinel's Ruby level (3.2.x -- matches tep's gemspec and
  # toy's `ruby "3.2.3"` engine marker, so a consumer pinned there can
  # `bundle lock` `gem "spinel_kit"` without a version conflict).
  s.required_ruby_version = ">= 3.2.0"

  # Ship only git-TRACKED files matching these globs (intersecting with
  # `git ls-files` keeps any stray build artifacts out). The `.reject` is a
  # belt-and-suspenders for a no-git build from an unpacked source tree.
  tracked = (`git ls-files -z`.split("\x0") rescue [])
  s.files = Dir[
    "README.md", "LICENSE", "CHANGELOG.md",
    # Declares SpinelKit's Spinel C-extension shape. It is empty ([]) --
    # SpinelKit is pure Ruby -- but ships at the gem root so `spinel-compat
    # vendor` finds it and records "no native build units" explicitly.
    "spinel-ext.json",
    # spin package manifest -- the same tree is an ordinary spin package
    # (issue #3); the package root is the require root, hence no lib/.
    "spin.toml",
    "spinel_kit.rb",
    "spinel_kit/**/*.rb",
    "sig/**/*.rbs",
    "docs/**/*.md"
  ].reject { |f| File.directory?(f) }
   .select { |f| tracked.empty? || tracked.include?(f) }

  # The package root is the require root (spin's package format: `require
  # "spinel_kit"` maps to ./spinel_kit.rb). The gem mirrors that with "."
  # so one tree serves both consumers.
  s.require_paths = ["."]

  # No runtime dependencies -- Spinel-compiled consumers vendor the lib/
  # directly. No development dependencies either: the parity tests use only
  # stdlib `minitest` (CRuby-side verification, never compiled).
end
