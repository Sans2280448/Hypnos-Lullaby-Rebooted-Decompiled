@tool
extends ColorRect

@export var glow_node: Node

@export_group("Movement")
@export var wobble_enabled: bool = true

@export_range(0.0, 500.0, 1.0)
var wobble_amount: float = 18.0

@export_range(0.0, 20.0, 0.01)
var wobble_speed: float = 0.35

@export_range(0.0, 360.0, 1.0)
var wobble_direction_degrees: float = 0.0

@export_range(0.0, 1.0, 0.01)
var wobble_side_amount: float = 0.35

@export_range(0.0, 5.0, 0.01)
var wobble_intensity: float = 1.0

@export var y_speed_multiplier: float = 0.85

var _time: float = 0.0
var _base_position: Vector2 = Vector2.ZERO
var _has_base_position: bool = false


func _ready() -> void :
	_base_position = position
	_has_base_position = true


func _process(_delta: float) -> void :
	if not _has_base_position:
		_base_position = position
		_has_base_position = true

	if not wobble_enabled:
		return

	var rot: = deg_to_rad(wobble_direction_degrees)
	var direction: = Vector2(cos(rot), sin(rot))
	var side_direction: = direction.orthogonal()

	var scaled_time: = _time * wobble_speed
	position = _base_position + (
		direction * sin(scaled_time)
		+ (side_direction * cos(scaled_time * y_speed_multiplier) * wobble_side_amount)
	) * wobble_amount * wobble_intensity


func set_wobble_intensity(value: float) -> void :
	wobble_intensity = value
