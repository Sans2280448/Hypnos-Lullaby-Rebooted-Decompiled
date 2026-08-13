class_name ChimeraFloatingControl extends Control

var _target_position: Vector2 = Vector2.ZERO
var _initial_position: Vector2 = Vector2.ZERO

func _ready() -> void :
	_initial_position = position

func _process(delta: float) -> void :
	reset_target_position()
	position = position.lerp(_target_position, delta)

func reset_target_position() -> void :
	_target_position = _initial_position
	_target_position.x += randf_range(-20, 20)
	_target_position.y += randf_range(-20, 20)

func close_enough_to_target() -> bool:
	return _target_position.distance_to(position) < 2.0
