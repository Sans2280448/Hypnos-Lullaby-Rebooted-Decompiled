@tool
extends Node
class_name CameraShake2D

signal shake_started
signal shake_finished

@export_group("Camera")
@export var camera: Camera2D

@export_group("Shake")
@export var trauma_decay: float = 2.5
@export var max_offset: Vector2 = Vector2(12.0, 12.0)
@export var max_rotation: float = 2.0
@export var noise_speed: float = 30.0
@export var trauma_power: float = 2.0

@export_group("Editor")
@export var editor_preview: = false:
	set(value):
		editor_preview = value

		if Engine.is_editor_hint():
			if value:
				shake(0.5)
			else:
				stop()

var trauma: = 0.0

var _noise: = FastNoiseLite.new()
var _time: = 0.0

var _base_offset: = Vector2.ZERO
var _base_rotation: = 0.0

var _shaking: = false


func _ready() -> void :
	if camera == null:
		camera = get_parent() as Camera2D

	if camera == null:
		push_error("CameraShake2D must be a child of a Camera2D.")
		set_process(false)
		return

	randomize()

	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.5

	_base_offset = camera.offset
	_base_rotation = camera.rotation

	set_process(false)


func _process(delta: float) -> void :
	if camera == null:
		return

	if trauma <= 0.0:
		stop()
		return

	_time += delta * noise_speed
	trauma = maxf(trauma - trauma_decay * delta, 0.0)

	var amount: = pow(trauma, trauma_power)

	var offset: = Vector2(
		_noise.get_noise_2d(_time, 0.0), 
		_noise.get_noise_2d(0.0, _time)
	) * max_offset * amount

	camera.offset = _base_offset + offset

	camera.rotation = _base_rotation + deg_to_rad(
		_noise.get_noise_2d(_time, 100.0) * max_rotation * amount
	)


func add_trauma(amount: float) -> void :
	if amount <= 0.0:
		return

	trauma = clampf(trauma + amount, 0.0, 1.0)
	_start()


func shake(strength: = 1.0) -> void :
	trauma = clampf(strength, 0.0, 1.0)
	_start()


func stop() -> void :
	if camera:
		camera.offset = _base_offset
		camera.rotation = _base_rotation

	if _shaking:
		shake_finished.emit()

	_shaking = false
	set_process(false)


func refresh_base() -> void :
	if camera:
		_base_offset = camera.offset
		_base_rotation = camera.rotation


func _start() -> void :
	if camera == null:
		return

	refresh_base()

	if !_shaking:
		_shaking = true
		shake_started.emit()

	set_process(true)
