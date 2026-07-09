# CRuby-side tests for SpinelKit::Hex. Asserts the hand-rolled hex codec
# matches CRuby's built-in conversions for the supported range.
require "minitest/autorun"
require "spinel_kit"

class HexTest < Minitest::Test
  H = SpinelKit::Hex

  def test_nibble_decodes_all_digits_both_cases
    "0123456789".each_char.with_index { |c, i| assert_equal i, H.nibble(c) }
    %w[a b c d e f].each_with_index { |c, i| assert_equal 10 + i, H.nibble(c) }
    %w[A B C D E F].each_with_index { |c, i| assert_equal 10 + i, H.nibble(c) }
  end

  def test_nibble_rejects_non_hex
    ["g", "G", "/", ":", " ", "z"].each { |c| assert_equal(-1, H.nibble(c)) }
  end

  def test_nibble_char_is_uppercase_hex
    (0..15).each { |n| assert_equal n.to_s(16).upcase, H.nibble_char(n) }
  end

  def test_byte2_is_two_lowercase_hex_chars
    [0, 7, 15, 16, 127, 255].each do |n|
      assert_equal format("%02x", n), H.byte2(n)
    end
  end

  def test_to_int_parses_leading_hex
    assert_equal 0x1a3, H.to_int("1a3")
    assert_equal 0xFF,  H.to_int("FF")
    assert_equal 0,     H.to_int("")
    assert_equal 0,     H.to_int("g")          # no leading hex digit
    assert_equal 0x10,  H.to_int("10;chunk")   # stops at first non-hex
  end

  def test_nibble_roundtrips_nibble_char
    (0..15).each { |n| assert_equal n, H.nibble(H.nibble_char(n)) }
  end
end
