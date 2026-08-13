@tool
class_name TypingChallenge extends Node


@export var celebi_start_scale: Vector2 = Vector2(0.7, 0.7)
@export var celebi_end_scale: Vector2 = Vector2(1.2, 1.2)

@export var show_celebi: bool = false:
	get:
		return _show_celebi
	set(val):
		if val != _show_celebi:
			if val:
				$Celebi.scale = celebi_start_scale
				$Celebi.modulate = Color(0.247, 0.247, 0.247, 1.0)

				celebi_animator.get_parent().visible = true
				celebi_animator.play(celebi_enter_animation)
				celebi_animator.seek(0.0)

			else:
				celebi_animator.get_parent().visible = false

		_show_celebi = val

@export var active: bool = false:
	get:
		return _active
	set(val):
		if _active != val:
			if val:
				initiate_challenge()
			else:
				end_challenge()

		if Debugger and Debugger.fps_display and "_disable_quick_restart" in Debugger.fps_display:
			Debugger.fps_display._disable_quick_restart = _active

		_active = val

@export var prompt_user: bool = false:
	get:
		return _prompt_user
	set(val):
		if _prompt_user != val:
			if val:
				start_challenge()

		_prompt_user = val

@export var autoplay: bool = false
@export var choose_from_list: bool = true

@export var time_end: float = 4.0:
	get:
		return _time_end
	set(val):
		if _time_end != val:
			passed_challenge = false
			challenge_over = false

		_time_end = val

@export var end_offset: float = 0.0

@export_group("Words", "word_")
@export var current_word: String = ""
@export var custom_word: String = ""
@export var word_list: Array[String] = ["report bug"]:
	set(val):
		if word_list != val:
			word_list = val
			_words_used.clear()

@export_group("Celebi", "celebi_")
@export var celebi_animator: AnimationPlayer
@export var celebi_enter_animation: StringName = &"Celebi idle"
@export var celebi_success_animation: StringName = &"Celebi return"
@export var celebi_fail_animation: StringName = &"Celebi Song"
@export var celebi_tick_animation: StringName = &"Celebi tick"
@export var celebi_tick_sprite: Node2D
@export var celebi_tick_offset: float = 0.5
@export var celebi_sound_tick: AudioStreamPlayer
@export var celebi_sound_tick_danger: AudioStreamPlayer
@export var celebi_sound_fail: AudioStreamPlayer
@export var celebi_curve: Curve

@export_group("Unown", "unown_")
@export var unown_scene: PackedScene
@export var unown_letter_parent: Node

@export_subgroup("Flyby", "unown_flyby_")
@export var unown_flyby: AnimationPlayer
@export var unown_flyby_animation: StringName = &"UnownFlyBy copy"

@export_group("References", "reference_")
@export var reference_level: RubiconLevel
@export var bar_animation: AnimationPlayer
@export var health_module: RubiconHealthModule

signal challenge_started
signal challenge_fail(failure: int)
signal force_second_fail

var fail_count: int = 0

var unowns: Array[UnownLetter] = []

var passed_challenge: bool = false
var challenge_over: bool = false
var letters_passed: int = 0

var _show_celebi: bool = false
var _active: bool = false
var _prompt_user: bool = false
var _time_end: float = 0.0

var _words_used: Array[String] = []

var _celebi_last_second: int = 0
var _celebi_tween: Tween

var _autoplay_time_passed: float = 0.0

func _process(delta: float) -> void :
	if reference_level == null or reference_level.clock == null or not active or not show_celebi or not prompt_user or challenge_over:
		return

	var current_time: float = reference_level.clock.animation_player.current_animation_position
	var time_left: float = time_end + end_offset - current_time

	if time_left <= 0:
		active = false
		return

	if autoplay and prompt_user:
		_autoplay_process(delta)

	if time_left > 6:
		celebi_tick_sprite.modulate.a = 0.4
	else:
		celebi_tick_sprite.modulate.a = 0.4 + ((1 - (time_left / 6.0)) * 0.6)

	var celebi_second: int = floori(time_left - celebi_tick_offset)

	if celebi_second != _celebi_last_second:
		if celebi_second == -1:
			celebi_sound_fail.play()
		elif celebi_second < 3:
			celebi_sound_tick_danger.play()
		else:
			celebi_sound_tick.play()

		celebi_animator.play(celebi_tick_animation if celebi_second >= 0 else celebi_fail_animation)
		celebi_animator.seek(0.0)

	_celebi_last_second = celebi_second

func _autoplay_process(delta: float) -> void :
	_autoplay_time_passed += delta

	if _autoplay_time_passed < 0.2:
		return

	input_letter(current_word[letters_passed])
	_autoplay_time_passed = 0.0

func _input(event: InputEvent) -> void :
	if autoplay:
		return

	if not active or not prompt_user or challenge_over:
		return

	if event is not InputEventKey or event.is_released() or event.is_echo():
		return

	var letter: String = event.as_text_key_label()
	input_letter(letter.to_lower())

func input_letter(character: String) -> void :
	while letters_passed < current_word.length() and current_word[letters_passed] == " ":
		letters_passed += 1

	if letters_passed >= current_word.length():
		passed_challenge = true
		end_challenge()
		return

	if character != current_word[letters_passed].to_lower():
		fail_current_unown()
		end_offset -= 0.25
		return

	letters_passed += 1

	while letters_passed < current_word.length() and current_word[letters_passed] == " ":
		letters_passed += 1

	if letters_passed >= current_word.length():
		passed_challenge = true
		end_challenge()
		return

	update_unowns()


func get_challenge_word() -> String:
	if choose_from_list:
		var word: String = word_list.pick_random()
		if _words_used.size() < word_list.size():
			while _words_used.has(word):
				word = word_list.pick_random()

		if not _words_used.has(word):
			_words_used.append(word)

		return word

	return custom_word


func update_unowns() -> void :
	for i in current_word.length():
		if not has_unown_index(i):
			continue

		var unown: UnownLetter = unowns[i]
		if current_word[i] == " ":
			unown.visible = false
			continue

		unown.visible = true

		if i == letters_passed:
			unown.move_to_front()
			unown.activate()
		elif i < letters_passed:
			unown.succeed()


func fail_current_unown() -> void :
	while letters_passed < current_word.length() and current_word[letters_passed] == " ":
		letters_passed += 1

	if letters_passed < unowns.size():
		unowns[letters_passed].fail()

	end_offset -= 0.25


func initiate_challenge() -> void :
	if reference_level == null or reference_level.clock == null:
		return

	var current_time: float = reference_level.clock.animation_player.current_animation_position
	var final_time: float = time_end + end_offset

	if current_time >= final_time or (current_time < final_time and challenge_over):
		return

	current_word = get_challenge_word()

	letters_passed = 0
	end_offset = 0.0

	passed_challenge = false
	challenge_over = false

	unown_flyby.play(unown_flyby_animation)
	unown_flyby.seek(0.0)

	for unown in unowns:
		unown.visible = false

	while unowns.size() < current_word.length():
		var unown: UnownLetter = unown_scene.instantiate()
		unown.visible = false

		unown_letter_parent.add_child(unown)
		unowns.append(unown)

	for i in range(current_word.length(), unowns.size()):
		unowns[i].visible = false

	var spacing_x: float = 160
	var size_multiplier: float = 1.0

	if current_word.length() > 10:
		size_multiplier = 10.0 / (current_word.length() - 1)

	var offset_x: float = spacing_x * size_multiplier * (current_word.length() - 1) * 0.5

	for word_index in current_word.length():
		var unown: UnownLetter = unowns[word_index]
		var current_character: String = current_word[word_index]

		unown.character = ""

		var random_scale: float = randf_range(0.6, 0.7) * size_multiplier
		unown.scale = random_scale * Vector2.ONE

		var random_x: float = (((spacing_x * word_index) + randf_range(-20, 20)) * size_multiplier) - offset_x
		var random_y: float = randf_range(-60, 60)

		unown.position = Vector2(random_x, random_y)

		if current_character == " ":
			unown.visible = false
		else:
			unown.visible = true
			unown.enter(randf_range(0.125, 1.0 / 3.0))


func start_challenge() -> void :
	if reference_level == null or reference_level.clock == null or not active:
		return

	var current_time: float = reference_level.clock.animation_player.current_animation_position
	var final_time: float = time_end + end_offset

	if current_time >= final_time or (current_time < final_time and challenge_over):
		return

	var time_left: float = final_time - current_time
	_celebi_last_second = floori(time_left - celebi_tick_offset)

	for word_index in current_word.length():
		var current_character: String = current_word[word_index]
		var unown: UnownLetter = unowns[word_index]

		unown.character = "" if current_character == " " else current_character

	letters_passed = 0
	update_unowns()

	challenge_started.emit()

	if _celebi_tween and _celebi_tween.is_running():
		_celebi_tween.kill()

	_celebi_tween = create_tween()
	_celebi_tween.tween_method(_celebi_tween_func, 0.0, 1.0, time_left)


func _celebi_tween_func(progress: float) -> void :
	var curve_progress: float = celebi_curve.sample(progress)
	$Celebi.scale = lerp(celebi_start_scale, celebi_end_scale, curve_progress)
	$Celebi.modulate = lerp(Color(0.247, 0.247, 0.247, 1.0), Color(1.0, 1.0, 1.0, 1.0), curve_progress)


func end_challenge() -> void :
	if challenge_over:
		return

	if passed_challenge:
		succeed()
	else:
		fail()


func succeed() -> void :
	passed_challenge = true
	challenge_over = true

	celebi_sound_tick.stop()
	celebi_sound_tick_danger.stop()
	celebi_sound_fail.stop()

	celebi_animator.play(celebi_success_animation)
	celebi_animator.seek(0.0)

	for i in current_word.length():
		if current_word[i] == " ":
			continue

		if has_unown_index(i):
			unowns[i].succeed()

	await get_tree().create_timer(0.5, false).timeout

	for i in current_word.length():
		if current_word[i] == " ":
			continue

		if has_unown_index(i):
			unowns[i].exit(randf_range(0.0, 0.2))


func add_one_fail() -> void :
	if fail_count >= 2:
		return

	fail_count += 1
	challenge_fail.emit(fail_count)

	if fail_count == 2:
		force_second_fail.emit()


func fail() -> void :
	challenge_over = true

	if _celebi_tween and _celebi_tween.is_running():
		_celebi_tween.kill()

	if celebi_animator.current_animation != celebi_fail_animation:
		if not celebi_sound_fail.playing:
			celebi_sound_fail.play()

		celebi_animator.play(celebi_fail_animation)
		celebi_animator.seek(0.0)

	for i in current_word.length():
		if current_word[i] == " ":
			continue

		if has_unown_index(i):
			unowns[i].succeed()

	fail_count += 1
	challenge_fail.emit(fail_count)

	if fail_count == 3:
		return

	await get_tree().create_timer(0.5, false).timeout

	for i in current_word.length():
		if current_word[i] == " ":
			continue

		if has_unown_index(i):
			unowns[i].exit(randf_range(0.0, 0.2))


func has_unown_index(index: int) -> bool:
	return index >= 0 and index < unowns.size() and is_instance_valid(unowns[index])
