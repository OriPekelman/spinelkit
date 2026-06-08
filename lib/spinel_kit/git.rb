# SpinelKit::Git -- git provenance read from .git/HEAD.
#
# WHY THIS EXISTS. Spinel-compiled tooling that stamps a `git:{sha,branch}`
# provenance field (toy's run_start events; any reproducible-build banner)
# can't reach for a git gem: `rugged` is a C extension (rejected by the
# spinelgems catalog), and `gitkite`/`git_manager` only reach the `clean`
# tier with unmet `needs:` (load-path-terminal). Reading `.git/HEAD` as a
# plain file is a dozen lines of pure Ruby with no FFI -- so this is that.
# Ported from Toy::Git; tep gains it for free.
#
# Behaviour: reads .git/HEAD; if it's a `ref: refs/heads/<branch>` pointer,
# the branch is the last path segment and the 40-char sha is read from the
# pointed-at ref file; if HEAD is detached (a raw sha), sha = that, branch =
# "HEAD". Anything missing/short -> "unknown". Caller-facing default stays
# "unknown"/"unknown" so a non-repo checkout is non-fatal.
#
# NAMING. The Toy::Git copy carried a `gi_` prefix on every member/local to
# dodge a Spinel whole-program-inference bug; that bug was fixed upstream
# (see docs/spinel-discipline.md), so this uses plain `sha`/`branch`.
#
# USAGE:
#   g = SpinelKit::Git.read
#   git_sha    = g.sha
#   git_branch = g.branch
module SpinelKit
  class Git
    def initialize(sha, branch)
      @sha    = sha
      @branch = branch
    end

    def sha
      @sha
    end

    def branch
      @branch
    end

    # Read provenance from ./.git/HEAD. Returns a SpinelKit::Git
    # (sha/branch).
    def self.read
      s = "unknown"
      b = "unknown"
      if File.exist?(".git/HEAD")
        head = File.read(".git/HEAD")
        if head.length > 0 && head[head.length - 1...head.length] == "\n"
          head = head[0...head.length - 1]
        end
        if head.length > 5 && head[0...5] == "ref: "
          ref_rel = head[5...head.length]
          pp = ref_rel.split("/")
          if pp.length >= 3
            b = pp[pp.length - 1]
          end
          ref_path = ".git/" + ref_rel
          if File.exist?(ref_path)
            sha_raw = File.read(ref_path)
            if sha_raw.length >= 40
              s = sha_raw[0...40]
            end
          end
        else
          if head.length >= 40
            s = head[0...40]
            b = "HEAD"
          end
        end
      end
      SpinelKit::Git.new(s, b)
    end
  end
end
