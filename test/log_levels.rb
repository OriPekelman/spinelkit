# spin test entry: SpinelKit::Log — deterministic snapshot (.expected).
# Covers the pure gating logic (level_value / should_log?). Line FORMATTING
# embeds Time.now and is exercised by writing through a Log and checking the
# stable parts — but not here: snapshots must be byte-stable, so the emit
# path stays in the CRuby suite.
require "spinel_kit/log"

puts SpinelKit::Log.level_value("debug")
puts SpinelKit::Log.level_value("info")
puts SpinelKit::Log.level_value("warn")
puts SpinelKit::Log.level_value("error")
puts SpinelKit::Log.level_value("bogus")

log = SpinelKit::Log.new
puts log.min_level
puts log.should_log?("debug")
puts log.should_log?("error")
log.set_level("warn")
puts log.should_log?("info")
puts log.should_log?("warn")
log.set_level("debug")
puts log.should_log?("debug")
