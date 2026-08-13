@tool
extends Control

@export var clock: RubiconLevelClock

@export_group("Unowns")
@export var unown_parent: Control

@export_group("Progress")
@export_range(0.0, 1.0, 0.001) var progress: float = 1.0:
	set(value):
		if is_equal_approx(progress, value):
			return
		progress = value
		_shader_dirty = true

@export_range(0.0, 1.0, 0.001) var hold_progress: float = 0.0:
	set(value):
		if is_equal_approx(hold_progress, value):
			return
		hold_progress = value
		_shader_dirty = true

@export_range(0.0, 1.0, 0.001) var hold_percent: float = 0.0:
	set(value):
		if is_equal_approx(hold_percent, value):
			return
		hold_percent = value
		_shader_dirty = true

@export_group("Style")
@export_enum("Normal", "Silhouette") var eye_style: int = 0:
	set(value):
		if eye_style == value:
			return
		eye_style = value
		_shader_dirty = true

@export_group("Stagger")
@export var use_stagger: bool = true:
	set(value):
		if use_stagger == value:
			return
		use_stagger = value
		_shader_dirty = true

@export_range(0.0, 1.0, 0.001) var stagger_amount: float = 0.65:
	set(value):
		if is_equal_approx(stagger_amount, value):
			return
		stagger_amount = value
		_shader_dirty = true

@export var reverse_stagger: bool = false:
	set(value):
		if reverse_stagger == value:
			return
		reverse_stagger = value
		_shader_dirty = true

@export_group("Movement")
@export var movement_enabled: bool = true
@export_range(0.0, 50.0, 0.01) var movement_speed: float = 1.0

@export_group("Wobble")
@export_range(0.0, 15.0, 0.01) var wobble_intensity: float = 1.0

@export_group("Violent Parent Shake")
@export var violent_shake_enabled: bool = false
@export_range(0.0, 500.0, 1.0) var violent_shake_amount: float = 2.0
@export_range(0.0, 250.0, 0.1) var violent_shake_speed: float = 200.0

const EYE_STYLE_PARAMETER: StringName = "eye_style"

var _time: float = 0.0
var _base_position: Vector2 = Vector2.ZERO
var _has_base_position: bool = false
var _shader_dirty: bool = true
var _unowns: Array[ColorRect]


func _ready() -> void :
	_capture_base_position()
	_update_unown_shaders()


func _process(delta: float) -> void :
	if not visible:
		return

	if movement_enabled:
		if clock != null:
			_time = (clock.time_milliseconds / 1000.0) * movement_speed
		else:
			_time += delta * movement_speed

	if _shader_dirty or Engine.is_editor_hint():
		_update_unown_shaders()

	_update_unown_wobble()
	_update_parent_shake()


func _get_unown_container() -> Control:
	if unown_parent != null:
		return unown_parent

	return self


func _capture_base_position() -> void :
	var container: Control = _get_unown_container()

	_base_position = container.position
	_has_base_position = true


func _update_parent_shake() -> void :
	var container: Control = _get_unown_container()

	if not _has_base_position:
		_capture_base_position()

	if not violent_shake_enabled or not movement_enabled:
		container.position = _base_position
		return

	container.position = _base_position + Vector2(
		sin(_time * violent_shake_speed), 
		cos(_time * violent_shake_speed * 1.37)
	) * violent_shake_amount


func _update_unown_wobble() -> void :
	var final_wobble_intensity: float = wobble_intensity

	if not movement_enabled:
		final_wobble_intensity = 0.0

	for unown: ColorRect in _get_unowns():
		if "_time" in unown:
			unown._time = _time

		if unown.has_method("set_wobble_intensity"):
			unown.call("set_wobble_intensity", final_wobble_intensity)


func _update_unown_shaders() -> void :
	if not is_inside_tree() or not visible:
		return

	var unowns: Array[ColorRect] = _get_unowns()
	var unown_count: int = unowns.size()

	if unown_count == 0:
		_shader_dirty = false
		return

	for index: int in range(unown_count):
		_update_unown_shader(unowns[index], index, unown_count)

	_shader_dirty = false


func _update_unown_shader(unown: ColorRect, index: int, unown_count: int) -> void :
	if "_time" in unown:
		unown._time = _time

	var shader_material: ShaderMaterial = unown.material as ShaderMaterial
	if shader_material == null:
		return

	var stagger_index: int = index
	if reverse_stagger:
		stagger_index = unown_count - 1 - index

	var shader_progress: float = progress
	var shader_hold_progress: float = hold_progress

	if use_stagger and unown_count > 1:
		shader_progress = _get_staggered_progress(progress, stagger_index, unown_count)
		shader_hold_progress = _get_staggered_progress(hold_progress, stagger_index, unown_count)

	unown.modulate.a = maxf(shader_progress, shader_hold_progress)
	shader_material.set_shader_parameter(EYE_STYLE_PARAMETER, eye_style)

	if not "glow_node" in unown or unown.glow_node == null:
		return

	unown.glow_node.progress_value = shader_progress
	unown.glow_node.hold_progress_value = shader_hold_progress
	unown.glow_node.eye_style = eye_style


func _get_staggered_progress(base_progress: float, index: int, unown_count: int) -> float:
	var normalized_index: float = index / maxf(unown_count - 1, 1.0)
	var start: float = normalized_index * stagger_amount
	var end: float = start + (1.0 - stagger_amount)

	if end <= start:
		return 1.0 if base_progress >= start else 0.0

	return smoothstep(start, end, base_progress)


func _get_unowns() -> Array[ColorRect]:
	if _unowns.is_empty():
		var container: Node = _get_unown_container()
		_get_parallax_unowns(container, _unowns)

	return _unowns


func _get_parallax_unowns(node: Node, unowns: Array[ColorRect]) -> void :
	for child: Node in node.get_children():
		if child is ColorRect:
			unowns.append(child)

		_get_parallax_unowns(child, unowns)
