# SpinelKit rake tasks. CRuby-side only -- these never get compiled; they
# verify the pure-Ruby shims behave identically to CRuby stdlib before the
# code is vendored into a Spinel build.
require "rake/testtask"

# The CRuby minitest suite lives in test/parity/ (spin treats top-level
# test/*.rb as compiled snapshot entries; subdirectories are ignored).
Rake::TestTask.new(:test) do |t|
  t.libs << "." << "test"
  t.pattern = "test/parity/*_test.rb"
  t.warning = false
end

# Syntax-check the RBS tree (advisory type seeds for the Spinel analyzer /
# IDE tooling). No-op-skips cleanly if the `rbs` gem isn't installed.
task :"rbs:validate" do
  sh "rbs -I sig validate" do |ok, _|
    warn "rbs not available -- skipping (gem install rbs to enable)" unless ok
  end
end

task default: :test
