@abstract extends Resource
class_name ImporterSpriteData

var tree_enabled: bool = true

var texture: Texture2D
var atlas: Variant
var atlas_path: String
var loop: bool = false
var check_dupped: bool = true
var use_frame_duration: bool = true
var fps: int = 24
var anim_aliases: Dictionary[String, String]

var animation_list: PackedStringArray:
	get:
		if animation_list == null or animation_list.is_empty():
			return get_animation_list()
		return animation_list

@abstract func read_atlas(atlas_path: String) -> void 

@abstract func get_animation_list()
