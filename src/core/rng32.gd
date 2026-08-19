# The HTML build's rng(), reproduced bit for bit.
#
# This matters more than it looks. The ground tiling, the wall courses and the
# 520 scattered props are all placed by this generator, so if it does not produce
# the SAME sequence the Godot village is a different village that merely looks
# similar. It also means placement can be compared against the original by
# value rather than by eye.
#
# The original:
#     function rng(seed){ return function(){
#       seed |= 0; seed = seed + 0x6D2B79F5 | 0;
#       let t = Math.imul(seed ^ seed >>> 15, 1 | seed);
#       t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
#       return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
#
# Two traps in porting it, both of which I hit:
#   * Math.imul keeps the LOW 32 bits of a 32-bit multiply. A plain `*` in
#     GDScript is 64-bit, so every product must be masked.
#   * `t + Math.imul(...) ^ t` parses as `(t + imul(...)) ^ t`, because + binds
#     tighter than ^. My first port dropped the `t +` entirely and produced a
#     completely different sequence.
class_name Rng32
extends RefCounted

const M := 0xFFFFFFFF

var s: int


func _init(seed_val: int) -> void:
	s = seed_val & M


func next() -> float:
	s = (s + 0x6D2B79F5) & M
	var t: int = ((s ^ (s >> 15)) * (1 | s)) & M
	t = ((t + ((((t ^ (t >> 7)) * (61 | t))) & M)) & M) ^ t
	t &= M
	return float((t ^ (t >> 14)) & M) / 4294967296.0
