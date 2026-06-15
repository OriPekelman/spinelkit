# SpinelKit::Json decoders -- back-compat shim.
#
# The flat-key JSON decoders (`get_str`/`get_int`/`get_float`/`get_int_array`/
# `has_key?` + walkers) were merged into spinel_kit/json.rb once the
# cross-method poly-degrade that justified the split was fixed (spinel master
# b60fbd7 -- see json.rb and docs/spinel-discipline.md). This file remains so
# that existing `require "spinel_kit/json_decoder"` call sites keep working;
# it just loads the unified codec.
require_relative "json"
