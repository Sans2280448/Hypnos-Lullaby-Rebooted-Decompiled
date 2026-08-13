@tool
class_name RubiconInterpolatedCamera2D extends Camera2D

@export_group("Position", "position_interpolate_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var position_interpolate_enabled: bool = true

@export var position_interpolate_target: Vector2 = Vector2.ZERO

@export var position_interpolate_offset: Vector2 = Vector2.ZERO



@export var position_interpolate_speed: float = 2.4

@export_group("Rotation (Degrees)", "rotation_interpolate_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var rotation_interpolate_enabled: bool = true:
	set(v):
		rotation_interpolate_enabled = v
		update_configuration_warnings()

@export_custom(PROPERTY_HINT_RANGE, "-360,360,0.1,radians_as_degrees") var rotation_interpolate_target: float = 0.0

@export_custom(PROPERTY_HINT_RANGE, "-360,360,0.1,radians_as_degrees") var rotation_interpolate_offset: float = 0.0



@export var rotation_interpolate_speed: float = 2.4

@export_group("Zoom", "zoom_interpolate_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var zoom_interpolate_enabled: bool = true

@export_custom(PROPERTY_HINT_LINK, "") var zoom_interpolate_target: Vector2 = Vector2.ONE

@export_custom(PROPERTY_HINT_LINK, "") var zoom_interpolate_offset: Vector2 = Vector2.ZERO



@export var zoom_interpolate_speed: float = 3.125

func _notification(what: int) -> void :
	match what:



		NOTIFICATION_EDITOR_PRE_SAVE:
			if position_interpolate_enabled:
				global_position = position_interpolate_target + position_interpolate_offset
			if rotation_interpolate_enabled:
				global_rotation = rotation_interpolate_target + rotation_interpolate_offset
			if zoom_interpolate_enabled:
				zoom = zoom_interpolate_target + zoom_interpolate_offset












func _process(delta: float) -> void :
	if position_interpolate_enabled:
		global_position = global_position.lerp(position_interpolate_target + position_interpolate_offset, position_interpolate_speed * delta)

	if rotation_interpolate_enabled:
		global_rotation_degrees = rad_to_deg(lerp_angle(global_rotation, rotation_interpolate_target + rotation_interpolate_offset, rotation_interpolate_speed * delta))

	if zoom_interpolate_enabled:
		zoom = zoom.lerp(zoom_interpolate_target + zoom_interpolate_offset, zoom_interpolate_speed * delta)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if ignore_rotation and rotation_interpolate_enabled:
		warnings.append(tr(&"ignore_rotation is enabled, rotation cannot be interpolated."))

	return warnings

func _set(property: StringName, value: Variant) -> bool:
	if property == &"ignore_rotation":
		update_configuration_warnings()
	return false
