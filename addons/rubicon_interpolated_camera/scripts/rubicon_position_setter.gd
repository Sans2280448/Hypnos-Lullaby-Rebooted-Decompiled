@tool
class_name RubiconPositionSetter extends Node


@export var position_enabled: bool = true


@export var position_follow: bool = false


@export var rotation_enabled: bool = true


@export var rotation_follow: bool = false

@export var point_map: Dictionary[StringName, Node] = {&"Opponent": null, &"Player": null}:
	set(value):
		point_map = value
		notify_property_list_changed()

@export_storage var _current_point: StringName:
	set(value):
		if value == _current_point or not point_map.has(value) or point_map[value] == null:
			return

			if value == null and not point_map.values()[0] == null:
				value = point_map.values()[0]

		_current_point = value
		set_process_internal(true)
		notify_property_list_changed()

		var target: Node = point_map[_current_point]
		if is_attached_to_2d_camera():
			if position_enabled:
				_camera_2d.position_interpolate_target = _get_2d_global_position(target)

			if rotation_enabled:
				_camera_2d.rotation_interpolate_target = target.global_rotation
		elif is_attached_to_3d_camera():
			if position_enabled:
				_camera_3d.position_interpolate_target = target.global_position

			if rotation_enabled:
				_camera_3d.basis_interpolate_target = target.global_basis

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	var points: PackedStringArray = []
	for point: StringName in point_map.keys():
		if point_map[point] == null:
			continue

		points.append(point)

	if points.is_empty():
		return []

	properties.append({
		name = &"current_point", 
		hint = PROPERTY_HINT_ENUM, 
		type = TYPE_STRING_NAME, 
		usage = PROPERTY_USAGE_EDITOR, 
		hint_string = ",".join(points), 
	})


	return properties

var _camera_2d: RubiconInterpolatedCamera2D
var _camera_3d: RubiconInterpolatedCamera3D

func is_attached_to_2d_camera() -> bool:
	return _camera_2d != null

func is_attached_to_3d_camera() -> bool:
	return _camera_3d != null

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_PARENTED:
			var parent: Node = get_parent()
			if parent is RubiconInterpolatedCamera2D:
				_camera_2d = parent
			elif parent is RubiconInterpolatedCamera3D:
				_camera_3d = parent
		NOTIFICATION_UNPARENTED:
			_camera_2d = null
			_camera_3d = null
		NOTIFICATION_INTERNAL_PROCESS:
			if not position_follow and not rotation_follow:
				return

			if not point_map.has(_current_point) or point_map[_current_point] == null:
				return

			var target: Node = point_map[_current_point]
			if position_follow:
				if is_attached_to_2d_camera():
					_camera_2d.position_interpolate_target = _get_2d_global_position(target)
				elif is_attached_to_3d_camera():
					_camera_3d.position_interpolate_target = target.global_position

			if rotation_follow:
				if is_attached_to_2d_camera():
					_camera_2d.rotation_interpolate_target = target.global_rotation
				elif is_attached_to_3d_camera():
					_camera_3d.basis_interpolate_target = target.global_basis

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not is_attached_to_2d_camera() and not is_attached_to_3d_camera():
		warnings.append("This node needs to be a child of a RubiconInterpolatedCamera2D or RubiconInterpolatedCamera3D to work.")

	return warnings


func _get_2d_global_position(node: Node) -> Vector2:
	if not ("position" in node) or node.position is not Vector2:
		return Vector2.ZERO

	var global_pos: Vector2 = node.position
	var parent: Node = get_parent()
	while parent != null:
		global_pos += _get_node_2d_position(parent)
		parent = parent.get_parent()

	return global_pos

func _get_node_2d_position(node: Node) -> Vector2:
	if node is Parallax2D or ParallaxBackground or ParallaxLayer:
		return Vector2.ZERO

	if not ("position" in node) or node.position is not Vector2:
		return Vector2.ZERO

	return node.position

func _get(property: StringName) -> Variant:
	if property == &"current_point":
		return _current_point

	return null

func _set(property: StringName, value: Variant) -> bool:
	if property == &"current_point":
		_current_point = value
		return true

	return false
