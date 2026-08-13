@tool
extends Camera3D

@export var follow_enabled: bool = false
@export var path_follow_path: NodePath:
	set(value):
		path_follow_path = value
		_update_path_follow()

var path_follow: PathFollow3D


func _ready() -> void :
	_update_path_follow()


func _process(_delta: float) -> void :
	if not follow_enabled:
		return

	if path_follow == null:
		_update_path_follow()

	if path_follow == null:
		return

	global_position = path_follow.global_position


func _update_path_follow() -> void :
	path_follow = get_node_or_null(path_follow_path) as PathFollow3D
