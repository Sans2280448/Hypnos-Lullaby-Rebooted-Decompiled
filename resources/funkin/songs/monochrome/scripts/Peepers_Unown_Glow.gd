@tool
extends Sprite2D

@export_group("Target")
@export var target_color_rect: ColorRect

@export_group("Scale")
@export var scale_multiplier: float = 1.35
@export var use_uniform_scale: bool = true

@export_range(0.0, 5.0, 0.01)
var y_scale_squeeze: float = 0.3

@export_group("Rotation")
@export var point_to_viewport_center: bool = true
@export var rotation_offset_degrees: float = 0.0

@export_group("Alpha")
@export var follow_shader_progress: bool = true

@export_range(0.0, 1.0, 0.001)
var alpha_multiplier: float = 1.0

@export_group("Eye Variant Multipliers")
@export var tiny_scale_multiplier: float = 0.85
@export var small_scale_multiplier: float = 1.0
@export var large_scale_multiplier: float = 1.2
@export var custom_scale_multiplier: float = 1.0

@export_group("Position")
@export var follow_center: bool = true
@export var position_offset: Vector2 = Vector2.ZERO

const EYE_SIZE_VARIANT_PARAMETER: StringName = "eye_size_variant"

var variant: int = 1:
	set(value):
		if variant == value:
			return
		variant = value
		_update_shader_variant()
		_update_scale_and_position_if_needed(true)

var eye_style: int = 0:
	set(value):
		if eye_style == value:
			return
		eye_style = value
		_update_alpha()

var progress_value: float = 1.0:
	set(value):
		if is_equal_approx(progress_value, value):
			return
		progress_value = value
		_update_alpha()

var hold_progress_value: float = 0.0:
	set(value):
		if is_equal_approx(hold_progress_value, value):
			return
		hold_progress_value = value
		_update_alpha()

var _last_size: Vector2 = Vector2.ZERO
var _last_variant: int = -999
var _viewport: Viewport
var _viewport_center: Vector2
var _texture_size: Vector2
var _is_editor: bool


func _ready() -> void :
	_viewport = get_viewport()
	_viewport_center = _viewport.get_visible_rect().size * 0.5
	_is_editor = Engine.is_editor_hint()

	if texture:
		_texture_size = texture.get_size()

	var shader_material: ShaderMaterial = _get_shader_material()
	if shader_material != null:
		var shader_variant = shader_material.get_shader_parameter(EYE_SIZE_VARIANT_PARAMETER)
		if shader_variant != null:
			variant = int(shader_variant)

	_update_glow(true)


func _process(_delta: float) -> void :
	_update_glow(_is_editor)


func _get_target() -> ColorRect:
	if target_color_rect == null:
		target_color_rect = get_parent() as ColorRect

	return target_color_rect


func _get_shader_material() -> ShaderMaterial:
	var target: ColorRect = _get_target()
	if target == null:
		return null
	else:
		return target.material as ShaderMaterial


func _update_glow(force_transform_update: bool = false) -> void :
	_update_scale_and_position_if_needed(force_transform_update)
	_update_alpha()

	if not point_to_viewport_center or _viewport == null:
		return

	var to_center: Vector2 = _viewport_center - global_position
	if to_center.x != 0.0:
		global_rotation = to_center.angle() + deg_to_rad(rotation_offset_degrees)


func _update_alpha() -> void :
	if eye_style == 1:
		modulate.a = 0.0
	elif follow_shader_progress:
		modulate.a = clampf(maxf(progress_value, hold_progress_value) * alpha_multiplier, 0.0, 1.0)


func _update_shader_variant() -> void :
	var shader_material: ShaderMaterial = _get_shader_material()
	if shader_material != null:
		shader_material.set_shader_parameter(EYE_SIZE_VARIANT_PARAMETER, variant)


func _update_scale_and_position_if_needed(force_update: bool = false) -> void :
	var target: = _get_target()
	if target == null:
		return

	if not force_update and target.size == _last_size and variant == _last_variant:
		return

	_last_size = target.size
	_last_variant = variant

	var final_size: Vector2 = target.size * scale_multiplier * get_variant_scale(variant)
	if _texture_size.x > 0.0 and _texture_size.y > 0.0:
		if use_uniform_scale:
			var uniform_size: float = maxf(final_size.x, final_size.y)
			scale = Vector2.ONE * (uniform_size / _texture_size.x)
		else:
			scale = final_size / _texture_size

		scale.y *= y_scale_squeeze

	if follow_center:
		position = target.size * 0.5 + position_offset


func get_variant_scale(variant_: int) -> float:
	match variant_:
		0:
			return tiny_scale_multiplier
		1:
			return small_scale_multiplier
		2:
			return large_scale_multiplier
		_:
			return custom_scale_multiplier
