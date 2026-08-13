@tool
extends Node
class_name CrawlTimingController

@export_tool_button("Start Crawling") var start_playtest = start_mechanic
@export_tool_button("Stop Crawling") var stop_playtesting = stop_mechanic

signal mechanic_success
signal mechanic_failed
signal opening_started
signal attempt_success
signal attempt_failed

enum CrawlingStatus{
	OFF, 
	TRAVELING, 
	OPENING, 
	COMPLETE, 
	FAILED, 
}

@export var autoplay: bool = false

@export_group("Input")
@export var possible_inputs: Array[StringName] = [
	&"lullaby_special", 
	&"mania_lane0", 
	&"mania_lane1", 
	&"mania_lane2", 
	&"mania_lane3", 
]

@export var input_display_names: Dictionary = {
	&"lullaby_special": "SPACE", 
	&"mania_lane0": "LEFT", 
	&"mania_lane2": "UP", 
	&"mania_lane1": "DOWN", 
	&"mania_lane3": "RIGHT", 
}

@export_group("References")

@export var inputs: RubiconLevelNoteInputMap
@export var path_follow: PathFollow3D
@export var key: AnimatedSprite2D
@export var timing_key: Sprite2D
@export var key_label: Label
@export var key_animation_player: AnimationPlayer
@export var crawl_animation_player: AnimationPlayer
@export var prying_animation_player: AnimationPlayer
@export var gameover_module: ChimeraGameoverModule

@export_group("Animation Names")
@export var idle_animation: StringName = &"idle"
@export var press_animation: StringName = &"press"
@export var crawl_left_animation: StringName = &"crawlL"
@export var crawl_right_animation: StringName = &"crawlR"
@export var prying_animation_prefix: String = "pry"

@export_group("Prompt Position")
@export var randomize_prompt_position: bool = true
@export var position_x_min: float = -1000.0
@export var position_x_max: float = 1000.0
@export var position_y_min: float = -1000.0
@export var position_y_max: float = 1000.0

@export_group("Traveling Hold Phase")
@export var required_travel_successes: int = 6
@export var travel_attempt_delay: float = 0.2
@export var wrong_key_reprompt_delay: float = 1.0
@export var hold_time_min: float = 0.55
@export var hold_time_max: float = 1.0

@export_group("Opening Spam Phase")
@export var required_opening_successes: int = 4
@export var opening_attempt_delay: float = 0.12
@export var spam_max_progress: float = 8.0
@export var spam_start_progress_percent: float = 0.5
@export var spam_add_per_press: float = 1.5
@export var spam_decay_per_second: float = 3.0

@export_group("Progress Visual")
@export var progress_empty_scale: Vector2 = Vector2.ZERO
@export var progress_full_scale: Vector2 = Vector2.ONE

@export_group("Path Movement")
@export var crawl_path_hold_time: float = 1.0
@export var path_move_time: float = 0.2

@export_group("Visuals")
@export var appear_time: float = 0.08
@export var success_pop_scale: Vector2 = Vector2(1.15, 1.15)
@export var fail_pop_scale: Vector2 = Vector2(0.8, 0.8)
@export var result_fade_time: float = 0.12

var mode: CrawlingStatus = CrawlingStatus.OFF
var succeeded: bool = false

var travel_successes: int = 0
var opening_successes: int = 0

var current_input: StringName = &""
var attempt_active: bool = false

var hold_required_time: float = 0.0
var hold_current_time: float = 0.0
var is_holding_correct_key: bool = false

var spam_progress: float = 0.0

var _visual_tween: Tween
var _path_tween: Tween
var _next_crawl_is_left: bool = true
var _mechanic_generation: int = 0

func _ready() -> void :
	if not Settings.applied.is_connected(_on_settings_changed):
		Settings.applied.connect(_on_settings_changed)

func check_completion() -> void :
	if not succeeded:
		gameover_module.switch_to_gameover()

func start_mechanic() -> void :
	_on_settings_changed()

	stop_tweens()
	_mechanic_generation += 1

	mode = CrawlingStatus.TRAVELING
	succeeded = false

	travel_successes = 0
	opening_successes = 0

	current_input = &""
	attempt_active = false

	hold_required_time = 0.0
	hold_current_time = 0.0
	is_holding_correct_key = false

	spam_progress = 0.0
	_next_crawl_is_left = true

	if crawl_animation_player != null:
		crawl_animation_player.stop()

	if prying_animation_player != null:
		prying_animation_player.stop()

	if path_follow != null:
		path_follow.progress_ratio = 0.0

	hide_prompt()
	start_next_attempt()

	print("Started crawl hold/spam mechanic")


func stop_mechanic() -> void :
	stop_tweens()
	_mechanic_generation += 1

	mode = CrawlingStatus.OFF
	attempt_active = false
	is_holding_correct_key = false

	if crawl_animation_player != null:
		crawl_animation_player.stop()

	if prying_animation_player != null:
		prying_animation_player.stop()

	hide_prompt()

	print("Stopped crawl hold/spam mechanic")


func _input(event: InputEvent) -> void :
	if !attempt_active:
		return

	if mode == CrawlingStatus.OFF or mode == CrawlingStatus.COMPLETE or mode == CrawlingStatus.FAILED:
		return

	if event.is_echo():
		return

	for input_name in possible_inputs:
		if input_name.begins_with("mania_"):
			if inputs.has_event_registered(event):
				var id: StringName = inputs.get_handler_id_for_event(event)
				if id == input_name:
					if event.is_pressed():
						handle_input_pressed(input_name)
						return
					else:
						handle_input_released(input_name)
						return
		else:
			if event.is_action_pressed(input_name):
				handle_input_pressed(input_name)
				return

			if event.is_action_released(input_name):
				handle_input_released(input_name)
				return


func _process(delta: float) -> void :
	if !attempt_active:
		return

	if autoplay:
		_autoplay_process(delta)

	match mode:
		CrawlingStatus.TRAVELING:
			process_hold_phase(delta)

		CrawlingStatus.OPENING:
			process_spam_phase(delta)

var _autoplay_time_passed: float = 0.0
func _autoplay_process(delta: float) -> void :
	match mode:
		CrawlingStatus.TRAVELING:
			_autoplay_time_passed += delta
			if _autoplay_time_passed < 0.5:
				return

			handle_input_pressed(current_input)

		CrawlingStatus.OPENING:
			_autoplay_time_passed += delta
			if _autoplay_time_passed < 0.161:
				return

			handle_input_pressed(current_input)
			_autoplay_time_passed = 0.0

func handle_input_pressed(input_name: StringName) -> void :

	if input_name != current_input:
		if mode == CrawlingStatus.TRAVELING:
			wrong_key_pressed()
		return

	play_key_press_animation()

	match mode:
		CrawlingStatus.TRAVELING:
			is_holding_correct_key = true

		CrawlingStatus.OPENING:
			spam_progress += spam_add_per_press
			spam_progress = clampf(spam_progress, 0.0, spam_max_progress)

			update_progress_visual(get_spam_percent())

			if spam_progress >= spam_max_progress:
				success_attempt()


func wrong_key_pressed() -> void :
	if !attempt_active:
		return

	attempt_active = false
	is_holding_correct_key = false

	play_fail_visual()
	attempt_failed.emit()

	await get_tree().create_timer(wrong_key_reprompt_delay).timeout

	if mode != CrawlingStatus.TRAVELING:
		return

	start_next_attempt()


func handle_input_released(input_name: StringName) -> void :
	if mode != CrawlingStatus.TRAVELING:
		return

	if input_name == current_input:
		is_holding_correct_key = false


func start_next_attempt() -> void :
	if mode == CrawlingStatus.OFF or mode == CrawlingStatus.COMPLETE or mode == CrawlingStatus.FAILED:
		return

	if possible_inputs.is_empty():
		push_warning("CrawlTimingController has no possible_inputs.")
		fail_mechanic()
		return

	stop_visual_tween()

	attempt_active = true
	current_input = possible_inputs.pick_random()

	hold_current_time = 0.0
	hold_required_time = randf_range(hold_time_min, hold_time_max)
	is_holding_correct_key = false

	if mode == CrawlingStatus.OPENING:
		spam_progress = spam_max_progress * spam_start_progress_percent

	update_label_text()
	randomize_prompt_position_now()
	show_prompt()

	if mode == CrawlingStatus.TRAVELING:
		update_progress_visual(0.0)
	else:
		update_progress_visual(get_spam_percent())



func process_hold_phase(delta: float) -> void :
	if !is_holding_correct_key:
		return

	hold_current_time += delta

	var progress: = 1.0

	if hold_required_time > 0.0:
		progress = clampf(hold_current_time / hold_required_time, 0.0, 1.0)

	update_progress_visual(progress)

	if progress >= 1.0:
		success_attempt()



func process_spam_phase(delta: float) -> void :
	spam_progress -= spam_decay_per_second * delta
	spam_progress = clampf(spam_progress, 0.0, spam_max_progress)

	update_progress_visual(get_spam_percent())

	if spam_progress <= 0.0:
		fail_attempt()


func success_attempt() -> void :
	if !attempt_active:
		return

	attempt_active = false
	is_holding_correct_key = false

	match mode:
		CrawlingStatus.TRAVELING:
			travel_successes += 1
			play_next_crawl_animation()
			queue_progress(travel_successes)

			if travel_successes >= required_travel_successes:
				enter_opening_mode()
			else:
				_autoplay_time_passed = 0.0

				play_success_visual()
				await get_tree().create_timer(travel_attempt_delay).timeout
				start_next_attempt()

		CrawlingStatus.OPENING:
			opening_successes += 1
			play_prying_animation(opening_successes)

			if opening_successes >= required_opening_successes:
				complete_mechanic()
			else:
				play_success_visual()
				await get_tree().create_timer(opening_attempt_delay).timeout
				start_next_attempt()

	attempt_success.emit()


func fail_attempt() -> void :
	if !attempt_active:
		return

	attempt_active = false
	is_holding_correct_key = false

	play_fail_visual()
	attempt_failed.emit()

	match mode:
		CrawlingStatus.TRAVELING:
			fail_mechanic()

		CrawlingStatus.OPENING:
			await get_tree().create_timer(opening_attempt_delay).timeout
			start_next_attempt()


func enter_opening_mode() -> void :
	mode = CrawlingStatus.OPENING
	opening_successes = 0

	tween_path_ratio(1.0)

	opening_started.emit()

	play_success_visual()
	await get_tree().create_timer(opening_attempt_delay).timeout
	start_next_attempt()


func complete_mechanic() -> void :
	mode = CrawlingStatus.COMPLETE
	succeeded = true

	stop_visual_tween()
	play_success_visual()

	mechanic_success.emit()

	print("Crawl mechanic complete")


func fail_mechanic() -> void :
	mode = CrawlingStatus.FAILED
	succeeded = false

	stop_visual_tween()
	play_fail_visual()

	mechanic_failed.emit()

	print("Crawl mechanic failed")


func queue_progress(success_count: int) -> void :
	var generation_at_start: = _mechanic_generation

	if crawl_path_hold_time > 0.0:
		await get_tree().create_timer(crawl_path_hold_time).timeout

	if generation_at_start != _mechanic_generation:
		return

	if mode == CrawlingStatus.OFF or mode == CrawlingStatus.FAILED:
		return

	update_progress(success_count)

func update_progress(success_count: int) -> void :
	var target_ratio: = 1.0

	if required_travel_successes > 0:
		target_ratio = clampf(
			float(success_count) / float(required_travel_successes), 
			0.0, 
			1.0
		)

	tween_path_ratio(target_ratio)

func update_path_progress() -> void :
	var target_ratio: = 1.0

	if required_travel_successes > 0:
		target_ratio = clampf(
			float(travel_successes) / float(required_travel_successes), 
			0.0, 
			1.0
		)

	tween_path_ratio(target_ratio)


func tween_path_ratio(target_ratio: float) -> void :
	if path_follow == null:
		return

	stop_path_tween()

	_path_tween = create_tween()
	_path_tween.tween_property(
		path_follow, 
		"progress_ratio", 
		target_ratio, 
		path_move_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func update_progress_visual(percent: float) -> void :
	percent = clampf(percent, 0.0, 1.0)

	if timing_key != null:
		timing_key.scale = progress_empty_scale.lerp(
			progress_full_scale, 
			percent
		)

	if key != null:
		var alpha: = key.modulate.a
		key.modulate = Color.WHITE.lerp(Color.BLACK, percent)
		key.modulate.a = alpha


func get_spam_percent() -> float:
	if spam_max_progress <= 0.0:
		return 1.0

	return clampf(spam_progress / spam_max_progress, 0.0, 1.0)


func update_label_text() -> void :
	if key_label == null:
		return

	if input_display_names.has(current_input):
		key_label.text = str(input_display_names[current_input])
	else:
		key_label.text = String(current_input).replace("ui_", "").to_upper()


func randomize_prompt_position_now() -> void :
	if !randomize_prompt_position:
		return

	if key == null:
		return

	key.position = Vector2(
		randf_range(position_x_min, position_x_max), 
		randf_range(position_y_min, position_y_max)
	)


func show_prompt() -> void :
	if key != null:
		key.visible = true
		key.scale = Vector2.ONE
		key.modulate = Color.WHITE
		key.modulate.a = 0.0

	if key_label != null:
		key_label.visible = true
		key_label.scale = Vector2.ONE
		key_label.modulate.a = 0.0

	if timing_key != null:
		timing_key.visible = true
		timing_key.modulate = Color.WHITE
		timing_key.modulate.a = 1.0

	play_key_idle_animation()

	_visual_tween = create_tween()
	_visual_tween.set_parallel(true)

	if key != null:
		_visual_tween.tween_property(key, "modulate:a", 1.0, appear_time)

	if key_label != null:
		_visual_tween.tween_property(key_label, "modulate:a", 1.0, appear_time)


func hide_prompt() -> void :
	if key != null:
		key.visible = false

	if timing_key != null:
		timing_key.visible = false

	if key_label != null:
		key_label.visible = false


func play_success_visual() -> void :
	stop_visual_tween()

	_visual_tween = create_tween()
	_visual_tween.set_parallel(true)

	if key != null:
		key.visible = true
		_visual_tween.tween_property(key, "scale", success_pop_scale, result_fade_time)
		_visual_tween.tween_property(key, "modulate:a", 0.0, result_fade_time)

	if key_label != null:
		key_label.visible = true
		_visual_tween.tween_property(key_label, "scale", success_pop_scale, result_fade_time)
		_visual_tween.tween_property(key_label, "modulate:a", 0.0, result_fade_time)

	_visual_tween.chain().tween_callback(hide_prompt)


func play_fail_visual() -> void :
	stop_visual_tween()

	_visual_tween = create_tween()
	_visual_tween.set_parallel(true)

	if key != null:
		key.visible = true
		_visual_tween.tween_property(key, "scale", fail_pop_scale, result_fade_time)
		_visual_tween.tween_property(key, "modulate:a", 0.0, result_fade_time)

	if key_label != null:
		key_label.visible = true
		_visual_tween.tween_property(key_label, "scale", fail_pop_scale, result_fade_time)
		_visual_tween.tween_property(key_label, "modulate:a", 0.0, result_fade_time)

	_visual_tween.chain().tween_callback(hide_prompt)


func play_next_crawl_animation() -> void :
	if crawl_animation_player == null:
		return

	var animation_to_play: StringName

	if _next_crawl_is_left:
		animation_to_play = crawl_left_animation
	else:
		animation_to_play = crawl_right_animation

	if crawl_animation_player.has_animation(animation_to_play):
		crawl_animation_player.play(animation_to_play)
	else:
		push_warning(
			"Crawl animation not found: %s" % String(animation_to_play)
		)

	_next_crawl_is_left = !_next_crawl_is_left


func play_prying_animation(attempt_number: int) -> void :
	if prying_animation_player == null:
		return

	var animation_name: = StringName(
		prying_animation_prefix + str(attempt_number)
	)

	if prying_animation_player.has_animation(animation_name):
		prying_animation_player.play(animation_name)
	else:
		push_warning(
			"Prying animation not found: %s" % String(animation_name)
		)


func play_key_idle_animation() -> void :
	if key_animation_player == null:
		return

	if key_animation_player.has_animation(idle_animation):
		key_animation_player.play(idle_animation)


func play_key_press_animation() -> void :
	if key_animation_player == null:
		return

	if key_animation_player.has_animation(press_animation):
		key_animation_player.play(press_animation)


func stop_tweens() -> void :
	stop_visual_tween()
	stop_path_tween()


func stop_visual_tween() -> void :
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()

	_visual_tween = null


func stop_path_tween() -> void :
	if _path_tween != null and _path_tween.is_valid():
		_path_tween.kill()

	_path_tween = null


func _on_player_body_entered(body: Node3D) -> void :

	check_completion()

func _on_settings_changed() -> void :
	if Settings._level_note_inputs:
		inputs = Settings._level_note_inputs

	for input_name in inputs.inputs.values():
		input_display_names[input_name] = _get_input_name(input_name)

	input_display_names["lullaby_special"] = _get_input_name(&"lullaby_special")

func _get_input_name(input_name: StringName) -> String:
	if autoplay:
		match input_name:
			&"mania_lane0":
				return "←"
			&"mania_lane1":
				return "↓"
			&"mania_lane2":
				return "↑"
			&"mania_lane3":
				return "→"

		return "◉"

	var input_event: InputEvent
	if not input_name.begins_with(&"mania"):
		input_event = InputMap.action_get_events(input_name)[0]
	else:
		for input_event_key in inputs.inputs:
			if inputs.inputs[input_event_key] == input_name:
				input_event = input_event_key
				break

	if input_event is InputEventKey:
		match input_event.keycode:
			KEY_LEFT:
				return "←"
			KEY_DOWN:
				return "↓"
			KEY_UP:
				return "↑"
			KEY_RIGHT:
				return "→"

	if input_event is InputEventJoypadButton:
		match input_event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				return "←"
			JOY_BUTTON_DPAD_DOWN:
				return "↓"
			JOY_BUTTON_DPAD_UP:
				return "↑"
			JOY_BUTTON_DPAD_RIGHT:
				return "→"

	return input_event.as_text().to_upper()
