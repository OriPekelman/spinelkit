# spin test entry: SpinelKit::Hex — deterministic snapshot (.expected).
# Also runs under CRuby byte-identically (the subset-parity property).
require "spinel_kit/hex"

# nibble: hex char -> 0..15, -1 for non-hex
puts SpinelKit::Hex.nibble("0")
puts SpinelKit::Hex.nibble("9")
puts SpinelKit::Hex.nibble("a")
puts SpinelKit::Hex.nibble("F")
puts SpinelKit::Hex.nibble("g")
puts SpinelKit::Hex.nibble(" ")

# nibble_char: 0..15 -> uppercase hex char
puts SpinelKit::Hex.nibble_char(0)
puts SpinelKit::Hex.nibble_char(10)
puts SpinelKit::Hex.nibble_char(15)

# byte2: byte -> two lowercase hex chars
puts SpinelKit::Hex.byte2(0)
puts SpinelKit::Hex.byte2(31)
puts SpinelKit::Hex.byte2(255)

# to_int: leading hex digits -> int
puts SpinelKit::Hex.to_int("ff")
puts SpinelKit::Hex.to_int("1A2b")
puts SpinelKit::Hex.to_int("10zz")
puts SpinelKit::Hex.to_int("")
