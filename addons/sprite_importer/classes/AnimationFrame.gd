extends RefCounted
class_name AnimationFrame

var anim_name: String

var frame_idx: int
var atlas_texture: AtlasTexture = AtlasTexture.new()
var atlas_margin: Rect2
var dupped_frame: bool
var frame_duration: int = 1
