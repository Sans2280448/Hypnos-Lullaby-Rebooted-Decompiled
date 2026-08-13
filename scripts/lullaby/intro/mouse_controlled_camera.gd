@tool
extends RubiconInterpolatedCamera2D


@export var mouse_movement_enabled: bool = false

var game_size: Vector2
var window: Window


func _ready() -> void :
	window = get_window()
	game_size = get_viewport().get_visible_rect().size


func _process(delta: float) -> void :
	if Engine.is_editor_hint():
		return

	if not mouse_movement_enabled:
		position_interpolate_enabled = false
		return
	else:
		position_interpolate_enabled = true




	var center: Vector2 = game_size / 2.0
	var window_size: Vector2i = window.get_size_with_decorations()
	var window_scale: Vector2 = Vector2(window_size) / game_size

	var screen_mouse_pos: Vector2i = DisplayServer.mouse_get_position()
	var screen_window_pos: Vector2i = window.get_position_with_decorations()
	var window_mouse_pos: Vector2 = (
		Vector2(screen_mouse_pos) - Vector2(screen_window_pos)
	)

	var scaled_mouse_pos: Vector2 = window_mouse_pos / window_scale
	position_interpolate_target = center
	position_interpolate_target -= (center - scaled_mouse_pos) / 8.0
	position_interpolate_target = position_interpolate_target.clamp(
		center - (Vector2.ONE * 40.0), 
		center + (Vector2.ONE * 40.0), 
	)

	position = lerp(position, position_interpolate_target, delta)
