require_relative "lib/spinel_kit/version"

Gem::Specification.new do |s|
  s.name        = "spinel_kit"
  s.version     = SpinelKit::VERSION
  s.summary     = "The Spinel stdlib-surface gem: pure-Ruby JSON/Git/Log shims for AOT-compiled apps"
  s.description = <<~TEXT.strip
    SpinelKit consolidates the pure-Ruby "stdlib substitute" shims that every
    Spinel-compiled project would otherwise hand-roll. Spinel (the Ruby->native
    AOT compiler) cannot lower the json gem's C-ext fast path / metaprogrammed
    fallback, stdlib Logger, or C-ext git bindings -- and the spinelgems
    compatibility catalog confirms no verified gem exists to reuse. So this gem
    ships a JSON encoder+decoder+builder, .git/HEAD provenance, and a minimal
    levelled logger. Pure Ruby, no native extension, no runtime dependencies --
    it vendors cleanly via bundler-spinel. Pre-alpha.
  TEXT
  s.authors     = ["Ori Pekelman"]
  s.email       = ["ori@pekelman.com"]
  s.license     = "MIT"
  s.homepage    = "https://github.com/OriPekelman/spinelkit"
  s.metadata    = {
    "source_code_uri"       => "https://github.com/OriPekelman/spinelkit",
    "bug_tracker_uri"       => "https://github.com/OriPekelman/spinelkit/issues",
    "documentation_uri"     => "https://github.com/OriPekelman/spinelkit#readme",
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
    "lib/**/*.rb",
    "sig/**/*.rbs",
    "docs/**/*.md"
  ].reject { |f| File.directory?(f) }
   .select { |f| tracked.empty? || tracked.include?(f) }

  s.require_paths = ["lib"]

  # No runtime dependencies -- Spinel-compiled consumers vendor the lib/
  # directly. No development dependencies either: the parity test uses only
  # stdlib `minitest` + `json` (CRuby-side verification, never compiled).
end
