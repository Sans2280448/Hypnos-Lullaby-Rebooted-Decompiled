@tool
extends Node
class_name SpriteShake2D

signal shake_started
signal shake_finished

@export_group("Target")
@export var target: Node2D

@export_group("Shake")
@export_range(0.0, 10.0, 0.01)
var trauma_decay: float = 2.5

@export var max_offset: Vector2 = Vector2(8.0, 8.0)

@export_range(0.0, 45.0, 0.1)
var max_rotation_degrees: float = 3.0

@export_range(0.0, 100.0, 0.1)
var noise_speed: float = 35.0

@export_range(0.1, 4.0, 0.1)
var trauma_power: float = 2.0

@export_group("Editor Preview")
@export var editor_preview: bool = false:
	set(value):
		editor_preview = value

		if not Engine.is_editor_hint():
			return

		if value:
			shake(editor_preview_strength)
		else:
			stop_shake()

@export_range(0.0, 1.0, 0.01)
var editor_preview_strength: float = 0.75

var trauma: float = 0.0

var _noise: = FastNoiseLite.new()
var _noise_time: float = 0.0

var _base_position: Vector2
var _base_rotation: float

var _is_shaking: bool = false


func _ready() -> void :
	if target == null:
		target = get_parent() as Node2D

	if target == null:
		push_error("SpriteShake2D must be a child of a Node2D or Sprite2D.")
		set_process(false)
		return

	_setup_noise()
	_capture_base_transform()

	set_process(false)

	if Engine.is_editor_hint() and editor_preview:
		shake(editor_preview_strength)


func _setup_noise() -> void :
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.5


func _process(delta: float) -> void :
	if target == null:
		set_process(false)
		return

	if Engine.is_editor_hint() and not editor_preview:
		stop_shake()
		return

	if trauma <= 0.0:
		stop_shake()
		return

	_noise_time += noise_speed * delta
	trauma = maxf(trauma - trauma_decay * delta, 0.0)

	var amount: = pow(trauma, trauma_power)

	var shake_offset: = Vector2(
		_noise.get_noise_2d(_noise_time, 0.0), 
		_noise.get_noise_2d(0.0, _noise_time)
	)

	shake_offset *= max_offset * amount

	target.position = _base_position + shake_offset

	var rotation_noise: = _noise.get_noise_2d(
		_noise_time, 
		_noise_time + 100.0
	)

	target.rotation = _base_rotation + deg_to_rad(
		rotation_noise * max_rotation_degrees * amount
	)

	if trauma <= 0.0:
		stop_shake()


func add_trauma(amount: float) -> void :
	if amount <= 0.0:
		return

	trauma = clampf(trauma + amount, 0.0, 1.0)
	_start_shake()


func shake(strength: float = 1.0) -> void :
	trauma = clampf(strength, 0.0, 1.0)

	if trauma <= 0.0:
		stop_shake()
		return

	_noise_time = randf_range(0.0, 1000.0)

	if not _is_shaking:
		_capture_base_transform()
		_is_shaking = true
		shake_started.emit()

	set_process(true)


func violent_shake() -> void :
	trauma = 1.0
	_noise_time += randf_range(50.0, 200.0)
	_start_shake()


func stop_shake() -> void :
	var was_shaking: = _is_shaking

	trauma = 0.0
	_is_shaking = false

	if target != null:
		target.position = _base_position
		target.rotation = _base_rotation

	set_process(false)

	if was_shaking:
		shake_finished.emit()


func refresh_base_transform() -> void :
	if _is_shaking:
		return

	_capture_base_transform()


func _capture_base_transform() -> void :
	if target == null:
		return

	_base_position = target.position
	_base_rotation = target.rotation


func _start_shake() -> void :
	if target == null:
		return

	if not _is_shaking:
		_capture_base_transform()
		_is_shaking = true
		shake_started.emit()

	set_process(true)
