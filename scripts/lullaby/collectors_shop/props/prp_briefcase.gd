class_name CollectorBriefcase
extends Node3D


@export var cartridges: Array[StringName] = []
@export var cartridge_model_map: Dictionary[StringName, CollectorBriefcaseCartridge] = {}

@export var mouse_controller: MouseController
@export var camera: Camera3D
@export var open_timer: Timer

@export var cartridge_target: Node3D

@export var shop: CollectorShop
@export var dialogue: CollectorDialogue

@export_group("Sound Effects")
@export var denied_sound: AudioStreamPlayer
@export var bought_sound: AudioStreamPlayer
@export var scroll_sound: AudioStreamPlayer
@export var select_sound: AudioStreamPlayer
@export var cancel_sound: AudioStreamPlayer

@export_group("HUD References", "hud_")
@export var hud_anims: AnimationPlayer
@export var hud_buy_button: Label
@export var hud_close_button: Label
@export var hud_cartridge_map: Dictionary[StringName, Node] = {}
@export var hud_in_timer: Timer
@export var hud_input_label: ShopBindUi

@export_group("Animation Players")
@export var animation_player: AnimationPlayer
@export var collector_anims: AnimationPlayer
@export var register_anims: AnimationPlayer
@export var camera_positions: AnimationPlayer
@export var falling_coin_anims: AnimationPlayer

var available_cartridges: Array[StringName]

var current_cart: StringName:
	get:
		if available_cartridges.is_empty():
			return &""
		else:
			return available_cartridges[cart_index]

var cart_index: int = 0
var button_index: int = 0:
	set(v):
		if button_index != v:
			button_index = v
			update_button_selection()

var active: = false
var is_focused: = false
var mid_anim: = false
var in_button_submenu: = false

var buttons_fade_tween: Tween
var cartridge_items_tween: Tween

var cartridge_tween: Tween
var cartridge_start_positions: Dictionary[StringName, Vector3] = {}
var cartridge_start_rotations: Dictionary[StringName, Vector3] = {}


func _ready() -> void :





	open_timer.timeout.connect(_on_open_timeout)
	update_available_cartridges()

	var index: = 0
	for key: StringName in cartridges:
		var already_unlocked: = SaveData.get_flag(&"%s_unlocked" % key)
		cartridge_model_map[key].material_anims.play(&"materials/%s" % key)
		hud_cartridge_map[key].visible = not already_unlocked

		if cart_index == index and already_unlocked:
			cart_index = mini(cart_index + 1, cartridges.size() - 1)

		index += 1


func _process(_delta: float) -> void :
	if mouse_controller.should_cast_ray:
		return

	if active:
		mid_anim = false

		@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
		mouse_controller.override_cursor_shape = -1


func _input(event: InputEvent) -> void :
	if not active:
		return

	if in_button_submenu:
		handle_button_input(event)
	else:
		handle_items_input(event)


func handle_button_input(event: InputEvent) -> void :
	if event.is_action_pressed(&"ui_right"):
		change_button_selection(1)
	if event.is_action_pressed(&"ui_left"):
		change_button_selection(-1)

	if event.is_action_pressed(&"ui_accept"):
		match button_index:
			0:
				try_buy_cart()
			1:
				exit_button_submenu()


func handle_items_input(event: InputEvent) -> void :
	if available_cartridges.is_empty():
		return

	if event.is_action_pressed(&"ui_down"):
		change_cart_selection(1)
	if event.is_action_pressed(&"ui_up"):
		change_cart_selection(-1)

	if event.is_action_pressed(&"ui_accept"):
		select_sound.play()
		in_button_submenu = true
		fade_buttons_to(1.0)
		update_button_selection()


func exit_button_submenu() -> void :
	cancel_sound.play()
	in_button_submenu = false
	fade_buttons_to(0.0)


func _on_open_timeout() -> void :
	hud_input_label.format_text = ""

	animation_player.play(&"BRIEFCASE0INTRO_132f")
	collector_anims.play(&"BRIEFCASE0INTRO_132f", 1.0)
	fade_buttons_to(0.0)

	await animation_player.animation_finished

	register_anims.play(&"open_with_briefcase")
	collector_anims.play(&"BRIEFCASE0IDLE_120f")

	for key: StringName in cartridges:
		var cart: = cartridge_model_map[key]
		var offsetter: = cart.animation_offset

		if key not in cartridge_start_positions:
			cartridge_start_positions[key] = offsetter.global_position

		if key not in cartridge_start_rotations:
			cartridge_start_rotations[key] = offsetter.global_rotation

	if not available_cartridges.is_empty():
		hud_anims.play(&"fade_in")

	hud_input_label.format_text = "[$ui_up$, $ui_down$] Movement, [$ui_accept$] Accept, [$ui_cancel$] Back"
	hud_in_timer.start()

	await hud_in_timer.timeout

	active = true
	change_cart_selection()


func open() -> void :
	is_focused = true
	in_button_submenu = false
	open_timer.start()
	camera_positions.play(&"interact_briefcase")

	var current_anim = collector_anims.current_animation

	if current_anim == "pose_idle_0" or current_anim == "pose_idle_4":
		collector_anims.play(&"pipe_trans", 0.2)
	elif current_anim == "pose_idle_1" or current_anim == "pose_idle_2":
		collector_anims.play(&"default_trans", 0.2)
	elif current_anim == "pose_idle_3" or "BRIEFCASE0OUTRO_100f":

		collector_anims.play(&"pose_idle_3", 0.5)

	await get_tree().create_timer(2.4).timeout
	dialogue.play_move_up()

	if all_games_unlocked():
		shop.play_voiceline_group("shop_boughtall", true)
	else:
		shop.play_voiceline_group("shop_enter", true)

	if mouse_controller:
		@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
		mouse_controller.override_cursor_shape = -1
		mouse_controller.should_cast_ray = false


func close() -> bool:
	if mid_anim or not active:
		return false

	if animation_player.current_animation != &"" or camera_positions.current_animation != &"":
		return false

	if in_button_submenu:
		exit_button_submenu()
		return false

	if cartridge_tween and cartridge_tween.is_running():
		cartridge_tween.kill()

	cartridge_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel()

	for key: StringName in cartridges:
		tween_out_cart_mesh(key)

	if not available_cartridges.is_empty():
		hud_anims.play(&"fade_out")

	hud_input_label.format_text = "[$ui_cancel$] Go Back"

	if mouse_controller:
		mouse_controller.should_cast_ray = true

	active = false
	is_focused = false
	camera_positions.play(&"interact_collector")
	animation_player.play(&"BRIEFCASE0OUTRO_100f")
	collector_anims.play(&"BRIEFCASE0OUTRO_100f")
	collector_anims.queue(&"pose_idle_3")
	collector_anims.set_blend_time(&"BRIEFCASE0OUTRO_100f", &"pose_idle_3", 0.5)
	register_anims.play(&"close_with_briefcase")

	dialogue.play_move_down()

	return true


func try_buy_cart() -> void :
	if mid_anim:
		return

	if SaveData.tokens < 1:
		denied_sound.play()
		return

	shop.stop_voiceline()
	bought_sound.play()

	var cart: = cartridge_model_map[current_cart]
	var hud_item: = hud_cartridge_map[current_cart]
	cart.dissolve_anims.play(&"actions/dissolve")

	falling_coin_anims.play("fall")

	SaveData.tokens -= 1
	SaveData.set_flag(&"%s_unlocked" % cart.key, true)
	SaveData.save()

	play_cart_dialogue(cart.key)
	update_available_cartridges()

	mid_anim = true
	active = false
	hud_item.get_node(^"SongName").text = hud_item.name

	exit_button_submenu()

	await cart.dissolve_anims.animation_finished
	cart.visible = false
	cart.process_mode = Node.PROCESS_MODE_DISABLED

	await shop.voiceline.finished

	if available_cartridges.is_empty():
		hud_anims.play(&"fade_out")

	var selected_item_tween = create_tween()\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_BACK)\
	.set_parallel()

	selected_item_tween.tween_property(hud_item, ^"modulate:a", 0.0, 0.5)
	selected_item_tween.tween_property(hud_item, ^"offset_transform_scale", Vector2.ONE, 0.35)
	selected_item_tween.tween_property(hud_item, ^"visible", false, 0.5)

	change_cart_selection()
	active = true


func all_games_unlocked() -> bool:
	if cartridges.is_empty():
		return false

	for key: StringName in cartridges:
		if not SaveData.get_flag(&"%s_unlocked" % key):
			return false

	return true


func update_available_cartridges() -> void :
	available_cartridges.clear()

	for key: StringName in cartridges:
		if not SaveData.get_flag(&"%s_unlocked" % key):
			available_cartridges.push_back(key)


func play_cart_dialogue(key: StringName) -> void :
	if key == &"":
		return

	var cart: = cartridge_model_map[key]
	shop.play_voiceline_group(cart.voiceline_group)


func change_button_selection(amount: int = 0) -> void :
	button_index = clampi(button_index + amount, 0, 1)

	if amount != 0:
		scroll_sound.play()

	update_button_selection()


func change_cart_selection(amount: int = 0) -> void :
	update_available_cartridges()

	if amount != 0:
		scroll_sound.play()

	if available_cartridges.is_empty():
		cart_index = 0
		return

	cart_index = clampi(cart_index + amount, 0, available_cartridges.size() - 1)

	if cartridge_items_tween and cartridge_items_tween.is_running():
		cartridge_items_tween.kill()
	if cartridge_tween and cartridge_tween.is_running():
		cartridge_tween.kill()

	cartridge_items_tween = create_tween()\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_BACK)\
	.set_parallel()
	cartridge_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel()

	for index: int in available_cartridges.size():
		var key: = available_cartridges[index]
		var already_unlocked: = SaveData.get_flag(&"%s_unlocked" % key)

		if already_unlocked:
			continue

		var hud_item: Control = hud_cartridge_map[key]
		if index == cart_index:
			tween_in_cart_mesh()
			hud_item.grab_focus.call_deferred()

			cartridge_items_tween.tween_property(hud_item, ^"modulate:a", 1.0, 0.5)
			cartridge_items_tween.tween_property(hud_item, ^"offset_transform_scale", Vector2.ONE * 1.1, 0.35)
		else:
			tween_out_cart_mesh(key)

			cartridge_items_tween.tween_property(hud_item, ^"modulate:a", 0.5, 0.5)
			cartridge_items_tween.tween_property(hud_item, ^"offset_transform_scale", Vector2.ONE, 0.35)


func tween_in_cart_mesh() -> void :
	var cart: = cartridge_model_map[current_cart]
	var offsetter: = cart.animation_offset
	var target_pos: = cartridge_target.global_position
	var target_rotation: = cartridge_target.global_rotation

	cartridge_tween.tween_property(offsetter, ^"global_position", target_pos, 0.45)\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_EXPO)
	cartridge_tween.tween_property(offsetter, ^"global_rotation", target_rotation, 0.45).set_ease(Tween.EASE_OUT)
	cartridge_tween.tween_callback( func():
		cart.float_anims.play(&"float")
	).set_delay(0.65)


func tween_out_cart_mesh(key: StringName) -> void :
	var cart: = cartridge_model_map[key]
	var offsetter: = cart.animation_offset

	cart.float_anims.stop()

	cartridge_tween.tween_property(offsetter, ^"global_position", cartridge_start_positions[key], 0.35).set_ease(Tween.EASE_OUT)
	cartridge_tween.tween_property(offsetter, ^"global_rotation", cartridge_start_rotations[key], 0.35).set_ease(Tween.EASE_OUT)


func fade_buttons_to(alpha: float) -> void :
	if buttons_fade_tween and buttons_fade_tween.is_running():
		buttons_fade_tween.kill()

	buttons_fade_tween = create_tween()\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_BACK)\
	.set_parallel()

	buttons_fade_tween.tween_property(hud_buy_button, ^"modulate:a", alpha, 0.5)
	buttons_fade_tween.tween_property(hud_close_button, ^"modulate:a", alpha, 0.5)


func update_button_selection() -> void :
	if buttons_fade_tween and buttons_fade_tween.is_running():
		buttons_fade_tween.kill()

	buttons_fade_tween = create_tween()\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_BACK)\
	.set_parallel()

	var selected: = hud_buy_button if button_index == 0 else hud_close_button
	buttons_fade_tween.tween_property(selected, ^"modulate:a", 1.0, 0.35)
	buttons_fade_tween.tween_property(selected, ^"offset_transform_scale", Vector2.ONE * 1.15, 0.4)

	var unselected: = hud_close_button if button_index == 0 else hud_buy_button
	buttons_fade_tween.tween_property(unselected, ^"modulate:a", 0.5, 0.85)
	buttons_fade_tween.tween_property(unselected, ^"offset_transform_scale", Vector2.ONE, 0.6)
