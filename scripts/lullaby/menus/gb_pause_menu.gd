class_name GBPauseMenu extends Control

@export var level: RubiconLevel
@export var paused: bool = false
@export var in_submenu: bool = false

@export var reference_title_text: Label
@export var reference_time_text: Label

@export var reference_music: AudioStreamPlayer
@export var reference_confirm: AudioStreamPlayer

signal credits_requested

var _music_time: float = 0.0
var _music_fade_tween: Tween

func resume() -> void :
	reference_confirm.play()

	if _music_fade_tween != null:
		_music_fade_tween.kill()

	_music_time = reference_music.get_playback_position()
	reference_music.stop()

	release_focus()
	get_tree().paused = false
	paused = false

func restart() -> void :
	reference_confirm.play()
	release_focus()
	SceneChanger.change_to(get_tree().current_scene.scene_file_path, &"hypno")

func exit() -> void :
	LullabyGameoverModule.has_died = false
	reference_confirm.play()
	release_focus()
	SceneChanger.change_to("res://rooms/env_collector_shop.tscn", &"hypno", true)

func show_credits() -> void :
	reference_confirm.play()
	release_focus()
	in_submenu = true
	credits_requested.emit()

func refocus() -> void :
	in_submenu = false

func _input(event: InputEvent) -> void :
	if not event.is_action_pressed("funkin_pause"):
		return

	var tree: SceneTree = get_tree()
	if tree.paused:
		return

	tree.paused = true
	paused = true

	if level != null:
		reference_title_text.text = level.metadata.title.to_upper()
		reference_time_text.text = "TIME: %s" % get_time_remaining()

	reference_music.volume_linear = 0.0
	reference_music.play(_music_time)

	_music_fade_tween = reference_music.create_tween()
	_music_fade_tween.tween_property(reference_music, "volume_linear", 0.3, 10.0)
	_music_fade_tween.play()

func get_time_remaining() -> String:
	if level == null:
		return "idk"

	var animation_player: AnimationPlayer = level.clock.animation_player
	var length: float = animation_player.current_animation_length
	var time: float = clampf(length - animation_player.current_animation_position, 0, length)
	var time_string: String = Time.get_time_string_from_unix_time(int(time))
	var times: PackedFloat64Array = time_string.split_floats(":")
	if times[0] == 0.0:
		return time_string.substr(time_string.find(":") + 1)
	else:
		return time_string
