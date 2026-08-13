class_name LullabyHideIfRelease extends Node

func _ready() -> void :
	get_parent().visible = OS.is_debug_build() or OS.has_feature("editor")
