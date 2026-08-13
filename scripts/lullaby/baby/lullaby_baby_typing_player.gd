class_name LullabyBabyTypingPlayer extends Node

@export var enabled: bool = false
@export var connect_to: TypingChallenge:
	set(val):
		if val == connect_to:
			return

		if connect_to:
			connect_to.challenge_started.disconnect(reset_attempt)
			connect_to.challenge_started.disconnect(_on_challenge_started)
			connect_to.challenge_fail.disconnect(_on_challenge_failed)

		connect_to = val
		connect_to.challenge_started.connect(reset_attempt)
		connect_to.challenge_started.connect(_on_challenge_started)
		connect_to.challenge_fail.connect(_on_challenge_failed)

@export_range(0.0, 1.0, 0.01) var success_chance: float = 0.75
@export var grace_period_time: float = 0.3

@export_group("Voice", "voice_")
@export var voice_speaker: AudioStreamPlayer
@export var voice_idle_sounds: Array[AudioStream]
@export var voice_interrupted: Array[AudioStream]
@export var voice_challenge_failed: Array[AudioStream]

@export var time_taken_range_start: float = 0.2
@export var time_taken_range_end: float = 1.2

var _grace_period_timer: float = 0.0
var _elapsed_time: float = 0.0
var _time_until_attempt: float = 0.0

var _attempt_succeed: bool = false
var _stop_trying: bool = false

func _process(delta: float) -> void :
	if _stop_trying:
		return

	if not enabled or not connect_to or not connect_to.active or not connect_to.prompt_user or connect_to.challenge_over:
		return

	if _grace_period_timer > 0.0:
		_grace_period_timer -= delta

	_elapsed_time += delta
	if _elapsed_time < _time_until_attempt:
		return

	var letter_input: InputEventKey = InputEventKey.new()
	letter_input.set_meta(&"baby_mode", true)
	letter_input.pressed = true

	if _attempt_succeed:
		var current_letter: String = connect_to.current_word[connect_to.letters_passed]
		letter_input.key_label = OS.find_keycode_from_string(current_letter)

	get_viewport().push_input(letter_input)
	reset_attempt()

func reset_attempt() -> void :
	if not enabled:
		return

	_elapsed_time = 0.0
	_time_until_attempt = randf_range(time_taken_range_start, time_taken_range_end)
	_attempt_succeed = randf_range(0.0, 1.0) < success_chance

func _on_challenge_started() -> void :
	if not enabled:
		return

	_stop_trying = false
	_grace_period_timer = grace_period_time

	if voice_speaker:
		voice_speaker.stream = voice_idle_sounds.pick_random()
		voice_speaker.play()

func _on_challenge_failed(_failure: int) -> void :
	if not enabled or _stop_trying:
		return

	if voice_speaker:
		voice_speaker.stream = voice_challenge_failed.pick_random()
		voice_speaker.play()

func _input(event: InputEvent) -> void :
	if _stop_trying or grace_period_time > 0.0:
		return

	if not enabled or not connect_to or not connect_to.active or not connect_to.prompt_user or connect_to.challenge_over:
		return

	if event.is_pressed() and event is InputEventKey and ( not event.has_meta(&"baby_mode") or event.get_meta(&"baby_mode") == false):
		_stop_trying = true
		if voice_speaker:
			voice_speaker.stream = voice_interrupted.pick_random()
			voice_speaker.play()
