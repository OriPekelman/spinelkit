# CRuby-side tests for SpinelKit::Git. These NEVER get compiled by Spinel --
# they run under CRuby to prove the .git/HEAD reader extracts sha/branch
# correctly. SpinelKit::Git.read reads from the CWD's ./.git, so each test
# builds a fake .git tree in a tmpdir and chdirs into it.
require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "spinel_kit"

class GitTest < Minitest::Test
  # Build a fake .git in a tmpdir with the given HEAD content + optional
  # ref file, chdir in, run SpinelKit::Git.read, return [sha, branch].
  def read_in_fake_repo(head, ref_path: nil, ref_sha: nil)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, ".git"))
      File.write(File.join(dir, ".git", "HEAD"), head)
      if ref_path
        full = File.join(dir, ".git", ref_path)
        FileUtils.mkdir_p(File.dirname(full))
        File.write(full, ref_sha)
      end
      Dir.chdir(dir) do
        g = SpinelKit::Git.read
        return [g.sha, g.branch]
      end
    end
  end

  SHA = "0123456789abcdef0123456789abcdef01234567"

  def test_simple_branch
    sha, branch = read_in_fake_repo("ref: refs/heads/main\n",
                                    ref_path: "refs/heads/main", ref_sha: SHA + "\n")
    assert_equal SHA, sha
    assert_equal "main", branch
  end

  # The regression this test exists for: a branch name with a slash
  # (feat/x) must NOT be truncated to its last segment ("x").
  def test_slashed_branch_name_is_preserved
    sha, branch = read_in_fake_repo("ref: refs/heads/feat/gh9-mixed-precision-f16\n",
                                    ref_path: "refs/heads/feat/gh9-mixed-precision-f16",
                                    ref_sha: SHA + "\n")
    assert_equal SHA, sha
    assert_equal "feat/gh9-mixed-precision-f16", branch
  end

  def test_deeply_slashed_branch_name
    _sha, branch = read_in_fake_repo("ref: refs/heads/user/feature/sub/thing\n",
                                     ref_path: "refs/heads/user/feature/sub/thing",
                                     ref_sha: SHA + "\n")
    assert_equal "user/feature/sub/thing", branch
  end

  def test_detached_head_raw_sha
    sha, branch = read_in_fake_repo(SHA + "\n")
    assert_equal SHA, sha
    assert_equal "HEAD", branch
  end

  def test_missing_ref_file_leaves_sha_unknown
    # HEAD points at a branch whose ref file doesn't exist (fresh branch,
    # unborn): branch is still parsed, sha stays "unknown".
    sha, branch = read_in_fake_repo("ref: refs/heads/feat/x\n")
    assert_equal "unknown", sha
    assert_equal "feat/x", branch
  end

  def test_no_git_dir_is_non_fatal
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        g = SpinelKit::Git.read
        assert_equal "unknown", g.sha
        assert_equal "unknown", g.branch
      end
    end
  end
end
