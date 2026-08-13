extends Node2D


@export var animation_player: AnimationPlayer
@export var music: AudioStreamPlayer
@export var skip_intro: bool = false

@export var health_module: RubiconHealthModule
@export var clock: RubiconLevelClock

@export var disable_for_skipping: bool = false

@export_group("Baby Mode", "baby_mode_")
@export var baby_mode_enabled: bool = false
@export var baby_mode_lines: Array[AudioStream]
@export var baby_mode_speaker: AudioStreamPlayer

var activated: bool = false

func _ready() -> void :
	if health_module:
		health_module.health_depleted.connect(activate_gameover, CONNECT_ONE_SHOT)


func _input(event: InputEvent) -> void :
	if not activated or event.is_echo() or not event.is_pressed():
		return
	if event.is_action(&"ui_accept"):
		animation_player.play(&"retry")
		if music:
			music.stop()
		await animation_player.animation_finished
		if is_inside_tree():
			get_tree().reload_current_scene()


func activate_gameover() -> void :
	if disable_for_skipping:
		return

	LullabyGameoverModule.has_died = true

	if clock and clock.animation_player:
		clock.animation_player.pause()

	if not animation_player:
		printerr("Needs animation player to play gameover cutscene!")
		return

	if skip_intro:
		animation_player.play(&"game_over_skip")
	else:
		animation_player.play(&"game_over")

	await animation_player.animation_finished

	if music:
		music.play()

	activated = true

	if not baby_mode_enabled or not baby_mode_speaker:
		return

	baby_mode_speaker.stream = baby_mode_lines.pick_random()
	baby_mode_speaker.play()
