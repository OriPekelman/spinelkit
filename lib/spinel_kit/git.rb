# SpinelKit::Git -- git provenance read from .git/HEAD.
#
# WHY THIS EXISTS. Spinel-compiled tooling that stamps a `git:{sha,branch}`
# provenance field (toy's run_start events; any reproducible-build banner)
# can't reach for a git gem: `rugged` is a C extension (rejected by the
# spinelgems catalog), and `gitkite`/`git_manager` only reach the `clean`
# tier with unmet `needs:` (load-path-terminal). Reading `.git/HEAD` as a
# plain file is a dozen lines of pure Ruby with no FFI -- so this is that.
# Ported verbatim from Toy::Git; tep gains it for free.
#
# Behaviour: reads .git/HEAD; if it's a `ref: refs/heads/<branch>` pointer,
# the branch is the last path segment and the 40-char sha is read from the
# pointed-at ref file; if HEAD is detached (a raw sha), sha = that, branch =
# "HEAD". Anything missing/short -> "unknown". Caller-facing default stays
# "unknown"/"unknown" so a non-repo checkout is non-fatal.
#
# SPINEL NAMING DISCIPLINE: whole-program inference is keyed partly on
# method- and local-variable NAMES. The reader members and every local
# carry a `gi_` prefix so they can't widen an unrelated `head`/`sha`/`pp`
# elsewhere in a compiled program. See docs/spinel-discipline.md.
#
# USAGE (keeps the historical local-variable names so call sites are
# untouched):
#   gp = SpinelKit::Git.read
#   git_sha    = gp.gi_sha
#   git_branch = gp.gi_branch
module SpinelKit
  class Git
    def initialize(gi_sha, gi_branch)
      @gi_sha    = gi_sha
      @gi_branch = gi_branch
    end

    def gi_sha
      @gi_sha
    end

    def gi_branch
      @gi_branch
    end

    # Read provenance from ./.git/HEAD. Returns a SpinelKit::Git
    # (gi_sha/gi_branch).
    def self.read
      gi_s = "unknown"
      gi_b = "unknown"
      if File.exist?(".git/HEAD")
        gi_head = File.read(".git/HEAD")
        if gi_head.length > 0 && gi_head[gi_head.length - 1...gi_head.length] == "\n"
          gi_head = gi_head[0...gi_head.length - 1]
        end
        if gi_head.length > 5 && gi_head[0...5] == "ref: "
          gi_ref_rel = gi_head[5...gi_head.length]
          gi_pp = gi_ref_rel.split("/")
          if gi_pp.length >= 3
            gi_b = gi_pp[gi_pp.length - 1]
          end
          gi_ref_path = ".git/" + gi_ref_rel
          if File.exist?(gi_ref_path)
            gi_sha_raw = File.read(gi_ref_path)
            if gi_sha_raw.length >= 40
              gi_s = gi_sha_raw[0...40]
            end
          end
        else
          if gi_head.length >= 40
            gi_s = gi_head[0...40]
            gi_b = "HEAD"
          end
        end
      end
      SpinelKit::Git.new(gi_s, gi_b)
    end
  end
end
