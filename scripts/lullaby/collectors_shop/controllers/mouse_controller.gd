class_name MouseController
extends Node

@export var can_click: bool = true
@export var ray_length: float = 35.0

@export_group("Reference")
@export var root: CollectorShop
@export var camera: Camera3D
@export var ray_cast: RayCast3D
@export var hand_animation_tree: AnimationTree


@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
var override_cursor_shape: Input.CursorShape = -1

const ROTATION_PAN_SPEED_DEGREES: = 120.0
const MIN_ROTATION_SPEED: = 4.0
const MAX_ROTATION_SPEED: = 12.0
const MAX_LEFT_ROTATION_DEGREES: = -90.0
const MAX_RIGHT_ROTATION_DEGREES: = 80.0
const EDGE_PERCENT: = 0.4

@export var should_cast_ray: bool:
	set(value):
		should_cast_ray = value
		if ray_cast:
			ray_cast.enabled = value

var colliding: = false

var _hand_state: StringName = &""
var _last_shop_state: CollectorShop.ShopStates
var _hand_state_machine: AnimationNodeStateMachinePlayback


func _ready() -> void :
	if hand_animation_tree:
		hand_animation_tree.active = true
		_hand_state_machine = hand_animation_tree.get("parameters/playback")

	if root != null:
		_last_shop_state = root.state

		if root.state == root.ShopStates.FREE_LOOK:
			_travel_hand(&"Activate")
		else:
			_travel_hand(&"Deactivate")
			if root.dialogue != null:
				root.dialogue.play_scale_out()

func _can_ray_cast() -> bool:
	return should_cast_ray and camera and ray_cast


func _is_free_look() -> bool:
	return root != null and root.state == root.ShopStates.FREE_LOOK


func _physics_process(_delta: float) -> void :
	if not _can_ray_cast():
		colliding = false
		if override_cursor_shape >= 0:
			Input.set_default_cursor_shape(override_cursor_shape)
		else:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return

	var mouse_position: = get_viewport().get_mouse_position()

	ray_cast.target_position = camera.project_ray_normal(mouse_position) * ray_length

	if root:
		ray_cast.collision_mask = root.state

	colliding = ray_cast.is_colliding()

	var collider: = ray_cast.get_collider()
	var clickable: = colliding and can_click
	if clickable and "can_interact" in collider:
		clickable = clickable and collider.can_interact

	if override_cursor_shape >= 0:
		Input.set_default_cursor_shape(override_cursor_shape)
	else:
		Input.set_default_cursor_shape(
			Input.CURSOR_POINTING_HAND if clickable else Input.CURSOR_ARROW
		)


func _process(delta: float) -> void :
	_update_hand_from_shop_state()

	if not _is_free_look():
		return

	if not get_window().has_focus():
		_travel_hand(&"Idle")
		return

	var direction: = _get_look_direction()

	_update_hand_animation(direction)

	if direction != 0.0:
		_update_camera_rotation(direction, delta)


func _update_hand_from_shop_state() -> void :
	if root == null:
		return

	if root.state == _last_shop_state:
		return

	_last_shop_state = root.state

	match root.state:
		root.ShopStates.FREE_LOOK:
			_travel_hand(&"Activate")

		root.ShopStates.BUSY, root.ShopStates.FOCUSED:
			_travel_hand(&"Deactivate")


func _get_look_direction() -> float:
	var keyboard_direction: = Input.get_axis("ui_right", "ui_left")

	if keyboard_direction != 0.0:
		return keyboard_direction

	return _get_mouse_edge_direction()


func _get_mouse_edge_direction() -> float:
	var viewport_width: = get_viewport().get_visible_rect().size.x
	var mouse_x: = get_viewport().get_mouse_position().x

	if mouse_x < 0.0 or mouse_x > viewport_width:
		return 0.0

	var edge_size: = viewport_width * EDGE_PERCENT

	if mouse_x < edge_size:
		return 1.0 - mouse_x / edge_size

	if mouse_x > viewport_width - edge_size:
		return - ((mouse_x - (viewport_width - edge_size)) / edge_size)

	return 0.0


func _update_camera_rotation(direction: float, delta: float) -> void :
	var strength = abs(direction)

	camera.rotation_interpolate_speed = lerp(
		MIN_ROTATION_SPEED, 
		MAX_ROTATION_SPEED, 
		strength
	)

	var rotation_speed = lerp(
		ROTATION_PAN_SPEED_DEGREES * 0.25, 
		ROTATION_PAN_SPEED_DEGREES, 
		strength
	)

	var rotation_target: Vector3 = camera.rotation_interpolate_target
	rotation_target.y += deg_to_rad(direction * rotation_speed) * delta






	camera.rotation_interpolate_target = rotation_target


func _update_hand_animation(direction: float) -> void :
	if _hand_state_machine == null:
		return

	var collider: = ray_cast.get_collider()

	if collider:
		if colliding and can_click and "can_interact" in collider:
			if collider.can_interact:
				_travel_hand(&"Point")
				return

	if direction > 0.0:
		if _hand_state != &"LeanLeft" and _hand_state != &"HoldLeft":
			_travel_hand(&"LeanLeft")
		return

	if direction < 0.0:
		if _hand_state != &"LeanRight" and _hand_state != &"HoldRight":
			_travel_hand(&"LeanRight")
		return

	_travel_hand(&"Idle")


func _travel_hand(state_name: StringName) -> void :
	if _hand_state_machine == null:
		return

	if _hand_state == state_name:
		return

	_hand_state = state_name
	_hand_state_machine.travel(String(state_name))


func _input(event: InputEvent) -> void :
	if not _is_confirm_event(event):
		return

	if not _can_ray_cast() or not colliding or not can_click:
		return

	var collider: = ray_cast.get_collider()

	if collider is not TriggerArea3D:
		print(collider)
		printerr("The selected Area3D is not interactable.")
		return

	collider.area_triggered.emit()
	collider.trigger()


func _is_confirm_event(event: InputEvent) -> bool:
	return (
		(event is InputEventMouseButton or event is InputEventJoypadButton)
		and event.is_action_pressed("RightClick")
	)
