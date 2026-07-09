# spin test entry: SpinelKit::Git — deterministic snapshot (.expected).
# Git.read walks ./.git (cwd-dependent), so the filesystem behaviours live in
# the CRuby suite with tmpdir fixtures; here we compile the surface and cover
# the value object deterministically.
require "spinel_kit/git"

g = SpinelKit::Git.new("a1b2c3d4e5f6a7b8c9d0a1b2c3d4e5f6a7b8c9d0", "feat/x")
puts g.sha
puts g.branch

u = SpinelKit::Git.new("unknown", "unknown")
puts u.sha
puts u.branch
