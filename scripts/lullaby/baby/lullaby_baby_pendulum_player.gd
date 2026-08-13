@tool
class_name LullabyBabyPendulumPlayer extends Node

@export var enabled: bool = false
@export var voice_speaker: AudioStreamPlayer
@export var connect_to: LullabyPendulumServer:
	set(val):
		if val == connect_to:
			return

		if connect_to:
			connect_to.hit_time_changed.disconnect(_hit_time_changed)

		connect_to = val
		connect_to.hit_time_changed.connect(_hit_time_changed)

@export var idle_sound_chance: float = 0.1
@export var cooldown_until_reactivation: float = 3.0

@export_group("Sound", "sound_")
@export var sound_idle_sounds: Array[AudioStream]
@export var sound_interrupted: Array[AudioStream]

@export_group("Hit Range", "hit_offset_range_")
@export var hit_offset_range_start: float = -125.0
@export var hit_offset_range_end: float = 125.0

var _next_hit_time: float = 0.0
var _time_until_reactivation: float = 0.0

func _process(delta: float) -> void :
	if not enabled or not connect_to or not connect_to.started or connect_to._pendulum_is_hit:
		return

	if _time_until_reactivation > 0.0:
		_time_until_reactivation -= delta
		return

	var millisecond_time: float = connect_to._level.clock.time_milliseconds
	if millisecond_time < _next_hit_time:
		return

	var pendulum_input: InputEvent = InputEventAction.new()
	pendulum_input.action = connect_to.input_action
	pendulum_input.set_meta(&"baby_mode", true)
	pendulum_input.pressed = true
	get_viewport().push_input(pendulum_input)

	if voice_speaker and not voice_speaker.playing and randf_range(0.0, 1.0) < idle_sound_chance:
		voice_speaker.stream = sound_idle_sounds.pick_random()
		voice_speaker.play()

func _hit_time_changed(hit_time: float) -> void :
	_next_hit_time = hit_time + randf_range(hit_offset_range_start, hit_offset_range_end)

func _input(event: InputEvent) -> void :
	if not enabled or not connect_to or not connect_to.started or _time_until_reactivation > 0.0:
		return

	if event.is_action_pressed(connect_to.input_action) and ( not event.has_meta(&"baby_mode") or event.get_meta(&"baby_mode") == false):
		_time_until_reactivation = cooldown_until_reactivation
		if voice_speaker:
			voice_speaker.stream = sound_interrupted.pick_random()
			voice_speaker.play()
