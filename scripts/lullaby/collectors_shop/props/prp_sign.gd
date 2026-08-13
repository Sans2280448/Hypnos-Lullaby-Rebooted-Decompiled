extends Node3D

@export var enabled: bool = false:
	set(value):
		enabled = value
		_update_visual()
@export var lerp_movement: bool = true

@export_group("Internal References")
@export var inactive_emission: Texture2D
@export var shop_emission: Texture2D
@export var talk_emission: Texture2D

@export var sign_player: AnimationPlayer

@export_group("Shop References")
@export var shop: CollectorShop
@export var note_pad: Node3D
@export var briefcase: CollectorBriefcase
@export var focus_area_center: TriggerArea3D

@export_group("Sign Positions")
@export var sign_base_position: Vector3 = Vector3(0.735, -0.392, -0.481)
@export var sign_selected_position: Vector3 = Vector3(0.735, -0.392, -0.481)
@export var sign_offscreen_offset: Vector3 = Vector3(3.6, -0.2, -0.4)
@export var sign_offscreen_anim_time: float = 0.78

@export_group("Selector Model")
@export var selector_model: Node3D
@export var selector_lerp_speed: float = 10.0
@export var shop_position: Vector3 = Vector3(0.0, 0.15, 0.0)
@export var talk_position: Vector3 = Vector3(0.0, -0.15, 0.0)

@export var override_lerp_pos: Vector3 = - Vector3.ONE

@onready var camera_positions: AnimationPlayer = %CameraPositions

@onready var shop_collision_box: Area3D = $Armature_002 / Skeleton3D / BoneAttachment3D / ShopCollisionArea
@onready var talk_collision_box: Area3D = $Armature_002 / Skeleton3D / BoneAttachment3D / TalkCollisionArea

@onready var mesh: MeshInstance3D = $Armature_002 / Skeleton3D / Cylinder

@onready var confirm_snd: AudioStreamPlayer3D = $Confirm
@onready var hover_snd: AudioStreamPlayer3D = $Hover

var current_option_index: int = -1
var current_option_name: String = ""
var mesh_mat: StandardMaterial3D
var options: Array[String] = ["shop", "talk"]

var _selector_target_position: Vector3 = Vector3.ZERO
var _sick_tween: Tween = null
var _sick_tween_progress: float = 0
var _in_menu: bool = false

func _ready() -> void :
	mesh_mat = mesh.get_active_material(0).duplicate()
	mesh.set_surface_override_material(0, mesh_mat)

	if selector_model != null:
		_selector_target_position = selector_model.position

	_update_visual()

	_setup_option_triggers(shop_collision_box, 0)
	_setup_option_triggers(talk_collision_box, 1)

func _process(delta: float) -> void :
	focus_area_center.input_ray_pickable = !enabled;

	if selector_model == null:
		return

	var elapsed_time: float = Time.get_ticks_msec() / 1000.0;

	if current_option_index == -1 and not _in_menu:
		_unselect_option()

	if enabled:
		focus_area_center.focused = not _in_menu
		shop.state = shop.ShopStates.BUSY if _in_menu else shop.ShopStates.FOCUSED

		if Input.is_action_just_released("ui_cancel") and _in_menu:
			exit_submenu()

		selector_model.position = selector_model.position.lerp(
			_selector_target_position, 
			1.0 - pow(0.0003, delta * selector_lerp_speed)
		)

		selector_model.position.x += sin(elapsed_time) * 0.0002 + sin(elapsed_time / 2) * 0.0001
		selector_model.position.y += cos(elapsed_time) * 0.0001 + sin(elapsed_time / 2) * 0.0001
		selector_model.position.z += sin(elapsed_time) * 5e-05 + cos(elapsed_time / 2) * 0.0001

		selector_model.rotation.x = sin(elapsed_time) * 0.03
		selector_model.rotation.z = cos(elapsed_time) * 0.025

		if current_option_index >= 0 and Input.is_action_just_released("left_click"):
			_select_option()

		if lerp_movement:
			position.x += sin(elapsed_time * 0.8) * 0.0003 + sin(elapsed_time / 2) * 0.0001
			position.y += cos(elapsed_time * 0.8) * 0.0003
	else:
		if Input.is_action_just_released("ui_cancel") and _sick_tween != null:
			_sick_tween.custom_step(999)
			_sick_tween.kill()
			_sick_tween = null

	if lerp_movement:
		var in_override: bool = override_lerp_pos != - Vector3.ONE
		var lerp_pos: Vector3 = sign_selected_position if current_option_index >= 0 else sign_base_position

		if in_override:
			lerp_pos = override_lerp_pos

		position = position.lerp(
			lerp_pos, 
			1.0 - pow(0.0003, delta * selector_lerp_speed if enabled else delta / 10.0)
		)

		var start_rot_lerp: bool = false;

		if sign_player.current_animation != null:
			start_rot_lerp = (sign_player.current_animation == &"" and enabled) or sign_player.current_animation == &"IntroFirst"

			if sign_player.current_animation == &"Intro" and sign_player.get_playing_speed() > 0 and sign_player.current_animation_position >= 0.9:
				start_rot_lerp = true;

		rotation.y = lerp(
			rotation.y, 
			deg_to_rad(-33.1) if start_rot_lerp else 0.0, 
			1.0 - pow(0.24, delta)
		)

func _setup_option_triggers(area: Area3D, id: int):
	area.mouse_entered.connect( func entered():
		if enabled:
			shop.mouse_controller.override_cursor_shape = Input.CURSOR_POINTING_HAND;

			var last_option_name: String = String(current_option_name)

			if current_option_index != id:
				current_option_index = id

			_update_visual()

			if last_option_name != current_option_name:
				hover_snd.play(0)
	)

	area.mouse_exited.connect( func exited():
		if enabled:
			current_option_index = -1
	)

func _unselect_option():
	@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
	shop.mouse_controller.override_cursor_shape = -1

	current_option_index = -1
	set_hover_option("")

var _allow_more_clicks: bool = true

func _select_option():
	if not _allow_more_clicks:
		return

	shop.stop_voiceline()

	selector_model.position.x += 0.01
	confirm_snd.play(0)

	enter_submenu()

	match current_option_index:
		0:
			briefcase.open()
		1:
			note_pad.open()

func _update_visual() -> void :
	if not enabled:
		set_hover_option("")
		return

	set_hover_option(options[current_option_index])

func set_hover_option(option: String) -> void :
	if mesh_mat == null:
		return

	if option != "":
		current_option_name = option

	match option:
		"shop":
			mesh_mat.emission_texture = shop_emission
			_selector_target_position = shop_position

		"talk":
			mesh_mat.emission_texture = talk_emission
			_selector_target_position = talk_position

		_:
			mesh_mat.emission_texture = inactive_emission

	mesh_mat.emission_enabled = true


func exit_submenu():
	if note_pad.visible:
		if not note_pad._allow_input:
			return
		else:
			note_pad.close()

	if briefcase.is_focused:
		if not briefcase.close():
			return

	enter_submenu(true)

func enter_submenu(is_exiting: bool = false):
	_in_menu = not is_exiting
	_allow_more_clicks = is_exiting
	note_pad.disable_collisions = is_exiting

	var final_position: Vector3 = sign_base_position + sign_offscreen_offset
	override_lerp_pos = sign_base_position

	if _sick_tween != null:
		_sick_tween.custom_step(999)
		_sick_tween.kill()
		_sick_tween = null

	_sick_tween = create_tween()
	_sick_tween.tween_method(
		func update(val: float):
			var eased_val: float = EasingFunctions.ease_in_out_circ(0.0, 1.0, val)
			override_lerp_pos = lerp(sign_base_position, final_position, eased_val)

			_sick_tween_progress = val, 
		1.0 if is_exiting else 0.0, 
		0.0 if is_exiting else 1.0, 
		sign_offscreen_anim_time
	)
