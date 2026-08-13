@tool
class_name RubiconInterpolatedCamera3D extends Camera3D

@export_group("Position", "position_interpolate_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var position_interpolate_enabled: bool = true

@export var position_interpolate_target: Vector3 = Vector3.ZERO

@export var position_interpolate_offset: Vector3 = Vector3.ZERO

@export var position_interpolate_speed: float = 2.4

@export_group("Rotation (Degrees)", "rotation_interpolate_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var rotation_interpolate_enabled: bool = true

@export_custom(PROPERTY_HINT_RANGE, "-180,180,0.1,radians_as_degrees") var rotation_interpolate_target: Vector3 = Vector3.ZERO

@export_custom(PROPERTY_HINT_RANGE, "-180,180,0.1,radians_as_degrees") var rotation_interpolate_offset: Vector3 = Vector3.ZERO

@export var rotation_interpolate_speed: float = 2.4

@export_group("Basis", "basis_interpolate_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var basis_interpolate_enabled: bool = false
@export var basis_interpolate_target: Basis = Basis.IDENTITY
@export var basis_interpolate_offset: Basis = Basis.IDENTITY
@export var basis_interpolate_speed: float = 2.4

@export_group("FOV", "fov_interpolate_")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var fov_interpolate_enabled: bool = true

@export var fov_interpolate_target: float = 75.0

@export var fov_interpolate_offset: float = 0.0

@export var fov_interpolate_speed: float = 3.125

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			if position_interpolate_enabled:
				global_position = position_interpolate_target + position_interpolate_offset
			if rotation_interpolate_enabled:
				global_rotation = rotation_interpolate_target + rotation_interpolate_offset
			if basis_interpolate_enabled:
				global_basis = basis_interpolate_target * basis_interpolate_offset
			if fov_interpolate_enabled:
				fov = fov_interpolate_target + fov_interpolate_offset





















func _process(delta: float) -> void :
	if position_interpolate_enabled:
		global_position = global_position.lerp(position_interpolate_target + position_interpolate_offset, position_interpolate_speed * delta)

	if rotation_interpolate_enabled:
		global_rotation_degrees = Vector3(
			rad_to_deg(lerp_angle(global_rotation.x, rotation_interpolate_target.x + rotation_interpolate_offset.x, rotation_interpolate_speed * delta)), 
			rad_to_deg(lerp_angle(global_rotation.y, rotation_interpolate_target.y + rotation_interpolate_offset.y, rotation_interpolate_speed * delta)), 
			rad_to_deg(lerp_angle(global_rotation.z, rotation_interpolate_target.z + rotation_interpolate_offset.z, rotation_interpolate_speed * delta))
		)

	if basis_interpolate_enabled:
		global_basis = global_basis.slerp(basis_interpolate_target * basis_interpolate_offset, basis_interpolate_speed * delta)

	if fov_interpolate_enabled:
		fov = lerpf(fov, fov_interpolate_target + fov_interpolate_offset, fov_interpolate_speed * delta)
