class_name CartridgeBagHandler
extends Node


@export var cart_disappearing: bool = false
@export var active: bool = false

@export var picked_mode: bool = false:
	set(v):
		if picked_mode != v:
			picked_mode = v

		if not picked_mode:
			current_cart = &""
			check_unlocked_songs()

			if cartridge_bag_sidepanel:
				cartridge_bag_sidepanel.reset_state()


				cartridge_bag_sidepanel._select_mode("freeplay")

@export_group("References")

@export var carts: Dictionary[StringName, Node] = {}

@export var story_mode: Array[StringName] = []
@export var freeplay: Array[StringName] = []

@export var animation_player: AnimationPlayer
@export var mouse_controller: MouseController
@export var sequences: ShopSequences
@export var cartridge_anim_player: AnimationPlayer

@export var console_area: FocusArea3D

@export var AudioPlayer: AudioStreamPlayer
@export var sidepanel_sub_viewport: SubViewport
@export var cartridge_bag_sidepanel: CartridgeBagSidepanel:
	set(v):
		if cartridge_bag_sidepanel != v:
			if cartridge_bag_sidepanel:
				cartridge_bag_sidepanel.mode_selected.disconnect(_on_mode_selected)

			cartridge_bag_sidepanel = v

			if cartridge_bag_sidepanel:
				cartridge_bag_sidepanel.mode_selected.connect(_on_mode_selected)

var current_mode: String = "freeplay":
	set(v):
		if current_mode != v:
			var prev: = current_mode
			current_mode = v
			_update_colliders(prev)

var current_cart: StringName = &""
var coming_from_console: bool = false


func _ready() -> void :
	_update_colliders(current_mode)
	check_unlocked_songs()


func _process(_delta: float) -> void :
	if ( not active) or ( not picked_mode):
		return

	if current_cart.is_empty():
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return

	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _input(event: InputEvent) -> void :
	if not active:
		return

	if not picked_mode:
		if event.is_pressed() and event.is_action(&"ui_cancel"):
			_exit(false)
		else:
			if sidepanel_sub_viewport:
				sidepanel_sub_viewport.push_input(event)
	else:
		if event.is_pressed() and event.is_action(&"ui_cancel"):

			_exit(false)



			AudioPlayer.stream = load("res://resources/audio/sfx/shop/console/sfx_soulroom_back.wav")
			AudioPlayer.play()

			for cart: StringName in carts.keys():
				unhover(cart, false)

		if event is InputEventMouseButton:
			event = event as InputEventMouseButton

			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				_try_select_cartridge()


func _try_select_cartridge() -> void :
	if current_cart.is_empty():
		return

	SaveData.cartridge_selected = current_cart
	SaveData.save()

	active = false
	cart_disappearing = true
	var node: Node = carts[current_cart]
	var cart_anim: AnimationPlayer = node.get_node("Offset/AnimationOffset/prp_cartridge/AnimationPlayer")
	cart_anim.play("actions/dissolve")
	await cart_anim.animation_finished

	_exit(true)

	await get_tree().create_timer(1.0).timeout
	cart_anim.play("RESET")
	node.get_node("Offset/AnimationPlayer").play("unhover")
	cart_disappearing = false


func _exit(right: bool) -> void :
	active = false
	picked_mode = false

	if mouse_controller:
		mouse_controller.should_cast_ray = true

	if sequences and sequences.animation_player:
		if coming_from_console and right and console_area:
			console_area.can_interact = true
			console_area.trigger()
			console_area.register_trigger()
		else:
			sequences.animation_player.play(&"focus_right" if right else &"focus_center")
			sequences.animation_player.seek(0.0, true)

		coming_from_console = false

	if animation_player:
		animation_player.play(&"cartridge_bag_close")

	if cartridge_anim_player:
		cartridge_anim_player.play(&"RESET")


func _on_mode_selected(mode: String) -> void :
	AudioPlayer.stream = load("res://resources/audio/sfx/shop/console/sfx_soulroom_select.wav")
	AudioPlayer.play()

	current_mode = mode
	picked_mode = true

	if cartridge_bag_sidepanel:
		cartridge_bag_sidepanel.update_song(&"", "???")


func _get_names(mode: String) -> Array[StringName]:
	match mode:
		"freeplay":
			return freeplay
		"story_mode":
			return story_mode
		_:
			return []


func _update_colliders(prev_mode: String) -> void :
	if cartridge_bag_sidepanel:
		cartridge_bag_sidepanel.reset_state()

	var prev_names: Array[StringName] = _get_names(prev_mode)
	for name_: StringName in prev_names:
		var node: Node = carts[name_]
		if node.has_node(^"Offset/Hitbox"):
			var hitbox: CollisionObject3D = node.get_node(^"Offset/Hitbox")
			for connection: Callable in hitbox.mouse_entered.get_connections():
				hitbox.mouse_entered.disconnect(connection)

			for connection: Callable in hitbox.mouse_exited.get_connections():
				hitbox.mouse_exited.disconnect(connection)

	var names: Array[StringName] = _get_names(current_mode)
	for name_: StringName in names:
		var node: Node = carts[name_]
		if node.has_node(^"Offset/Hitbox"):
			var hitbox: CollisionObject3D = node.get_node(^"Offset/Hitbox")
			hitbox.mouse_entered.connect(hover.bind(name_))
			hitbox.mouse_exited.connect(unhover.bind(name_))


func check_unlocked_songs():
	for cart in carts.keys():
		carts[cart].visible = SaveData.get_flag(StringName(str(cart) + "_unlocked"))


func hover(cart: StringName) -> void :
	if ( not active) or ( not picked_mode):
		return

	current_cart = cart

	var node: Node = carts[cart]
	if cartridge_bag_sidepanel:
		cartridge_bag_sidepanel.update_song(cart, node.get_meta(&"display_name", cart))

	if not node.has_node(^"Offset/AnimationPlayer"):
		return

	var anim_player: AnimationPlayer = node.get_node(^"Offset/AnimationPlayer")
	anim_player.play(&"hover", 0.2)


func unhover(cart: StringName, force: bool = false) -> void :
	if (( not active) or ( not picked_mode)) and not force or cart_disappearing:
		return

	if current_cart == cart:
		current_cart = &""

		if cartridge_bag_sidepanel:
			cartridge_bag_sidepanel.update_song(&"", "???")

	var node: Node = carts[cart]
	if not node.has_node(^"Offset/AnimationPlayer"):
		return

	var anim_player: AnimationPlayer = node.get_node(^"Offset/AnimationPlayer")
	if ( not force) or anim_player.assigned_animation != &"unhover":
		anim_player.play(&"unhover", 0.2)
