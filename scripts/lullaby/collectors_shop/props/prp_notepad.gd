extends Node3D

signal free_soultoken()

@export var disable_collisions: bool = true:
	set(v):
		disable_collisions = v

		for area: Area3D in _collision_boxes:
			area.get_node(^"CollisionShape3D").disabled = disable_collisions

@export var notebook_base_pos: Vector3 = Vector3(0.643, 2.108, 2.24)
@export var notebook_offscreen_offset: Vector3 = Vector3.ZERO
@export var notebook_offscreen_anim_time: float = 0.78
@export var override_lerp_pos: Vector3 = - Vector3.ONE

@export var selectable_color: Color = Color.WHITE
@export var seen_color: Color = Color.RED

@onready var camera_positions: AnimationPlayer = %CameraPositions
@export var shop: CollectorShop
@export var dialogue: CollectorDialogue
@export var sign: Node3D
@onready var hover_snd: AudioStreamPlayer = $HoverSound
@export var collector: Collector

@onready var collsion_box: Area3D = $TextCollisionBox0
@onready var selector: ColorRect = %SelectRect
@onready var page_text: Label = %"Page Text 0"
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sub_viewport: SubViewport = %SubViewport
@onready var page_display: Sprite3D = $"Page Display"
@onready var shader_mat: ShaderMaterial = page_display.material_override


@export var options: Array[Dictionary] = [
	{
		"title": "Who are you?", 
		"voiceline": "ask_who", 
		"unlock_option_id": 1
	}, 
	{
		"title": "What's your zodiac?", 
		"voiceline": "ask_who_2", 
		"indented": true, 
		"hidden": true
	}, 
	{
		"title": "What is the console?", 
		"voiceline": "ask_console"
	}, 
	{
		"title": "Why rap battles?", 
		"voiceline": "ask_why"
	}, 
	{
		"title": "Where are we?", 
		"voiceline": "ask_where", 
		"unlock_option_id": 5
	}, 
	{
		"title": "No, like, where are we?", 
		"voiceline": "ask_where_2", 
		"indented": true, 
		"hidden": true
	}, 
	{
		"title": "What am I doing?", 
		"voiceline": "ask_what"
	}, 
	{
		"title": "I found a Soultoken!", 
		"voiceline": "ask_getsoultoken", 
		"unlock_option_id": 8, 
		"hidden": true
	}, 
	{
		"title": "Can I get a Soultoken?", 
		"voiceline": "ask_free_soultoken", 
		"indented": true, 
		"hidden": true, 
		"annoying": true
	}, 
]
var option_voicelines_to_id: Dictionary[String, int]

var _sick_tween: Tween = null
var _sick_tween_progress: float = 0

var _collision_boxes: Array[Area3D] = []

func _ready() -> void :
	_reload_page()

const TEXT_ITEM_SIZE: float = 81.5

func _reload_page():
	option_voicelines_to_id = {}
	option_voicelines_to_id.set(options[0].voiceline, 0)

	for i in range(1, options.size()):
		option_voicelines_to_id.set(options[i].voiceline, i)

	for index in SaveData.notepad_ids_unlocked:
		options[index].set("hidden", false)

	if SaveData.get_flag(&"safety_lullaby_beaten"):
		var ask_soultoken_id: int = option_voicelines_to_id.get("ask_getsoultoken")
		options[ask_soultoken_id].set("hidden", false)

		if not SaveData.notepad_ids_seen.has(ask_soultoken_id):
			SaveData.notepad_ids_seen.push_back(ask_soultoken_id)
			SaveData.save()

		var free_soultoken_id: int = option_voicelines_to_id.get("ask_free_soultoken")
		options[free_soultoken_id].set("hidden", false)


	sub_viewport.remove_child(selector)

	for child in get_children():
		if child.has_meta("box_id") and child.get_meta("box_id") != 0:
			remove_child(child)
			child.queue_free()

		if child.has_meta("text_id") and child.get_meta("text_id") != 0:
			sub_viewport.remove_child(child)
			child.queue_free()

	collsion_box.set_meta("box_id", 0)
	collsion_box.set_meta("full_id", 0)
	collsion_box.get_node(^"CollisionShape3D").set_deferred(&"disabled", true)
	_collision_boxes.push_back(collsion_box)

	page_text.text = options[0].title
	page_text.set_meta("text_id", 0)
	page_text.set_meta(
		&"text_size", 
		page_text.get_theme_font(&"font").get_string_size(
			page_text.text, 
			HORIZONTAL_ALIGNMENT_LEFT, 
		), 
	)

	_size_collision_box(collsion_box, page_text.get_meta(&"text_size").x)

	page_text.position.x = 40.0
	page_text.position.y = 13.0

	var hidden_count: int = 0;

	for i in range(1, options.size()):
		var indented: bool = options[i].has("indented") and options[i].get("indented")

		var text_position: Vector2 = Vector2(page_text.position)
		text_position.x = page_text.position.x + (70.0 if indented else 0.0)
		text_position.y = page_text.position.y - 1.0 + (TEXT_ITEM_SIZE * i)

		text_position.y -= hidden_count * TEXT_ITEM_SIZE

		var new_page_text: Label = page_text.duplicate()
		new_page_text.name = "Page Text " + str(i)
		new_page_text.set_meta(&"text_id", i)
		new_page_text.position = text_position
		new_page_text.text = options[i].title
		new_page_text.label_settings = new_page_text.label_settings.duplicate()
		new_page_text.set_meta(
			&"text_size", 
			new_page_text.get_theme_font(&"font").get_string_size(
				new_page_text.text, 
				HORIZONTAL_ALIGNMENT_LEFT, 
			), 
		)

		sub_viewport.add_child(new_page_text)

		var collision_position: Vector3 = Vector3(collsion_box.position)
		collision_position.y -= BOX_ITEM_SIZE * i

		collision_position.y += hidden_count * BOX_ITEM_SIZE

		var new_collision_box: Area3D = collsion_box.duplicate()
		new_collision_box.name = "TextCollisionBox" + str(i)
		new_collision_box.position = collision_position
		new_collision_box.set_meta("box_id", i - hidden_count)
		new_collision_box.set_meta("full_id", i)
		new_collision_box.get_node(^"CollisionShape3D").set_deferred(&"disabled", true)

		_size_collision_box(new_collision_box, new_page_text.get_meta(&"text_size").x, -0.014 if indented else 0.0)
		add_child(new_collision_box)
		_collision_boxes.push_back(new_collision_box)

		if options[i].has("hidden") and options[i].get("hidden"):
			new_collision_box.position.x += BOX_OFFSCREEN_OFFSET
			new_collision_box.set_meta("offscreen", true)

			new_page_text.visible = false
			hidden_count += 1

	var shader_material: ShaderMaterial = selector.material
	shader_material.set_shader_parameter("colors_to_mask", [seen_color, selectable_color])

	sub_viewport.add_child(selector)

const BOX_OFFSCREEN_OFFSET: float = 9999
const BOX_ITEM_SIZE: float = 0.017

func _size_collision_box(box: Area3D, text_width: float, offset: float = 0):
	var shape3d: CollisionShape3D = null
	if box.get_child(0) is CollisionShape3D:
		shape3d = box.get_child(0) as CollisionShape3D

		if shape3d.shape is BoxShape3D:
			var box3d: BoxShape3D = shape3d.shape.duplicate()
			box3d.size.x = (0.02 / 24.0) * text_width

			box.position.x = box3d.size.x / 2.0
			box.position.x -= 0.075 + offset

			shape3d.shape = box3d

var _unlock_tweens: Array[Tween] = []

func unlock_option(index: int):
	var option = options[index]

	for tween in _unlock_tweens:
		tween.custom_step(999)
		tween.kill()

	_unlock_tweens.resize(0)

	if not option.has("hidden") or not option.get("hidden"):
		return

	option.set("hidden", false)

	if not SaveData.notepad_ids_unlocked.has(index):
		SaveData.notepad_ids_unlocked.push_back(index)
		SaveData.save()

	for child in get_children():
		if child.has_meta("full_id"):
			var full_id: int = child.get_meta("full_id")
			if full_id == index:
				child.position.x -= BOX_OFFSCREEN_OFFSET
				child.set_meta("offscreen", false)
			elif full_id > index:
				child.position.y -= BOX_ITEM_SIZE

				child.set_meta("box_id", child.get_meta("box_id") + 1)

	for child in sub_viewport.get_children():
		if child.has_meta("text_id"):
			var text_id: int = child.get_meta("text_id")

			if text_id == index:
				child.visible = true

				var scale_up: Tween = create_tween()

				scale_up.tween_method(
					func update(val: float):
						var eased_val: float = EasingFunctions.ease_in_out_circ(0.0, 1.0, val)
						child.scale = Vector2(eased_val, eased_val), 
					0.0, 1.0, 0.5
				)

				_unlock_tweens.push_back(scale_up)
			elif text_id > index:
				var final_y: float = child.position.y + TEXT_ITEM_SIZE

				var slide_down: Tween = create_tween()

				slide_down.tween_method(
					func update(val: float):
						var eased_val: float = EasingFunctions.ease_in_out_circ(0.0, 1.0, val)
						child.position.y = lerp(child.position.y, final_y, eased_val), 
					0.0, 1.0, 0.5
				)

				_unlock_tweens.push_back(slide_down)

var _current_voiceline: String

func _select_option(id: int):
	shop.stop_voiceline()

	var offset_id: int = id

	for child in get_children():
		if child.has_meta("offscreen") and child.get_meta("offscreen"):
			continue

		if child.has_meta("box_id") and child.get_meta("box_id") == id:
			offset_id = child.get_meta("full_id")

	id = offset_id

	if options[id] != null and options[id].voiceline != null:
		_allow_input = false

		if SaveData.notepad_ids_seen.has(id):
			shop.play_voiceline_group("ask_reask")
			setup_voice_end_handler()

			_end_call = func():
				if options[id].has("annoying") and options[id].get("annoying"):
					var group: VoicelineGroup = shop._check_voiceline_group(options[id].voiceline)


					var index: int = randi_range(0, group.voicelines.size() - 1 - 1)
					shop._group_indexes.set(options[id].voiceline, index)

					_allow_input = false

					shop.play_voiceline_group(options[id].voiceline, false, false)
					setup_voice_end_handler()
				else:
					_allow_input = false

					shop.play_full_voiceline_group(options[id].voiceline)
					setup_voice_end_handler(true, id)

		elif options[id].has("annoying") and options[id].get("annoying"):
			shop.play_voiceline_group(options[id].voiceline, false, false)
			setup_voice_end_handler()

			_end_call = func annoying_end():
				var group: VoicelineGroup = shop._check_voiceline_group(options[id].voiceline)
				var index: = shop._group_indexes.get(options[id].voiceline, 0) as int

				if index >= group.voicelines.size():
					if not SaveData.notepad_ids_seen.has(id):
						SaveData.notepad_ids_seen.push_back(id)
						SaveData.save()

					free_soultoken.emit()

		else:
			shop.play_full_voiceline_group(options[id].voiceline)
			setup_voice_end_handler(true, id)

var _end_call
var _end_handler

func setup_voice_end_handler(is_group: bool = false, id: int = 0):
	_end_call = null

	if is_group:
		_end_handler = func finished():
			if visible:
				if not SaveData.notepad_ids_seen.has(id):
					SaveData.notepad_ids_seen.push_back(id)
					SaveData.save()

				if options[id].has("unlock_option_id"):
					unlock_option(options[id].get("unlock_option_id"))

				_allow_input = true

				if _end_call != null:
					_end_call.call()

		shop.voice_group_finished.connect(_end_handler, CONNECT_ONE_SHOT)
	else:
		_end_handler = func finished():
			if visible:
				_allow_input = true

			if _end_call != null:
				_end_call.call()

		shop.voice_entry_finished.connect(_end_handler, CONNECT_ONE_SHOT)

func remove_end_handler():
	if shop.voice_group_finished.is_connected(_end_handler):
		shop.voice_group_finished.disconnect(_end_handler)

	if shop.voice_entry_finished.is_connected(_end_handler):
		shop.voice_entry_finished.disconnect(_end_handler)

var _last_id: int = -1;
var _allow_input: bool = true

const APPEAR_SPEED: float = 0.8;
const APPEAR_FADED: float = 0.1;
var _appear_mult: float = 0;
var _appear_min: float = 0;

func _process(delta: float) -> void :
	if not sign.enabled and not sign._in_menu:
		if _sick_tween_progress > 0.95:
			visible = false
			return

	var hover_id: int = update_hover() if _allow_input else _last_id

	selector.position.y = 80.0 * hover_id

	var appear_progress: float = shader_mat.get_shader_parameter("appear_progress")
	var next_progress: float = clamp(appear_progress + (APPEAR_SPEED * _appear_mult * delta), _appear_min, 1.0)
	shader_mat.set_shader_parameter("appear_progress", next_progress)

	if visible:
		if hover_id >= 0 and _allow_input:
			shop.mouse_controller.override_cursor_shape = Input.CURSOR_POINTING_HAND;

			if _last_id != hover_id:
				_last_id = hover_id
				hover_snd.play(0.0)

			if Input.is_action_just_released("left_click"):
				_select_option(hover_id)
		else:
			@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
			shop.mouse_controller.override_cursor_shape = -1

		for child in sub_viewport.get_children():
			if child.has_meta("text_id"):
				var text_id: int = child.get_meta("text_id")
				if SaveData.notepad_ids_seen.has(text_id):
					child.label_settings.font_color = seen_color
				else:
					child.label_settings.font_color = selectable_color

	var elapsed_time: float = Time.get_ticks_msec() / 1000.0;

	position = position.lerp(
		override_lerp_pos if override_lerp_pos != - Vector3.ONE else notebook_base_pos, 
		1.0 - pow(0.0003, delta)
	)

	position.x += sin(elapsed_time) * 5e-05
	position.y += cos(elapsed_time) * 6e-05

	rotation.x = deg_to_rad(-0.2) + (sin(elapsed_time) * 0.08)
	rotation.y = deg_to_rad(-20.4) + (cos(elapsed_time + 1.0) * 0.08)

func update_hover() -> int:
	if camera == null:
		return -1

	var mouse = get_viewport().get_mouse_position()

	var origin = camera.project_ray_origin(mouse)
	var dir = camera.project_ray_normal(mouse).normalized()

	var query = PhysicsRayQueryParameters3D.create(
		origin, 
		origin + dir * 1000.0
	)

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result: Dictionary = space_state.intersect_ray(query)
	var hit_id: int = -1

	if result and result.has("collider"):
		var collider = result["collider"]
		if collider.has_meta("box_id"):
			hit_id = collider.get_meta("box_id")

	return hit_id

func open_page():
	anim_player.play(&"Page 1")

func close_page():
	anim_player.play_backwards(&"Page 1")


func close():
	open(true)

func open(is_exiting: bool = false):

	var final_position: Vector3 = notebook_base_pos + notebook_offscreen_offset
	override_lerp_pos = notebook_base_pos

	if _sick_tween != null:
		_sick_tween.custom_step(999)
		_sick_tween.kill()
		_sick_tween = null

	if not is_exiting:
		transition_collector(true)

		dialogue.play_move_up()

		_allow_input = true

		shader_mat.set_shader_parameter("appear_progress", 0.0)
		_appear_mult = 1.0

		if camera_positions.current_animation != &"interact_notepad":
			camera_positions.play(&"interact_notepad")
	else:
		transition_collector(false)
		dialogue.play_move_down()

		_appear_mult = -1.0


		if camera_positions.current_animation != &"interact_collector":
			camera_positions.play("interact_collector")

		anim_player.play_backwards(&"Page 1")

	await get_tree().create_timer(0.15 if is_exiting else 0.2).timeout

	visible = not is_exiting;

	_sick_tween = create_tween()
	_sick_tween.tween_method(
		func update(val: float):
			var eased_val: float = EasingFunctions.ease_in_out_circ(0.0, 1.0, val)
			override_lerp_pos = lerp(notebook_base_pos, final_position, eased_val)

			_sick_tween_progress = val

			if not is_exiting:
				if val > 0.1:
					visible = true

				if val > 0.95 and anim_player.current_animation != &"Page 1":
					anim_player.play(&"Page 1")
			else:
				if val > 0.95:
					visible = false, 
		1.0 if is_exiting else 0.0, 
		0.0 if is_exiting else 1.0, 
		notebook_offscreen_anim_time
	)

func _on_collector_shop_voice_interrupted() -> void :
	if visible:
		var old_group_name: String = shop.voiceline_group_name
		var index: int = shop._group_indexes.get(shop.voiceline_group_name) - 1

		shop._group_indexes.set(shop.voiceline_group_name, index)

		remove_end_handler()
		shop.stop_voiceline()

		shop.play_voiceline_group("ask_interrupt")
		setup_voice_end_handler()

		_end_call = func resume():
			_allow_input = false

			shop.play_full_voiceline_group(old_group_name, false)
			setup_voice_end_handler(true, option_voicelines_to_id.get(old_group_name))

func _on_free_soultoken() -> void :


	print("GOT FREE SOULTOKEN!!!")

	SaveData.tokens += 1
	SaveData.save()



func transition_collector(intro: bool):
	var current_anim = collector.animation_player.current_animation

	if intro:
		if current_anim == "pose_idle_0" or current_anim == "pose_idle_4":
			collector.animation_player.play(&"pipe_trans", 0.3)
			await collector.animation_player.animation_finished
		elif current_anim == "pose_idle_1" or current_anim == "pose_idle_2":
			collector.animation_player.play(&"default_trans", 0.5)
			await collector.animation_player.animation_finished
		elif current_anim == "pose_idle_3":
			await get_tree().create_timer(1).timeout
		collector.animation_player.play(&"talk_intro")
	else:
		collector.animation_player.play(&"talk_outro")

		collector.animation_player.queue(&"pose_idle_3")
