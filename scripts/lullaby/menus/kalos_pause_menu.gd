class_name KalosPauseMenu extends Control

@export var active: bool = true
@export var level: RubiconLevel
@export var paused: bool = false
@export var credits_shown: bool = false
@export var exit_button: Control

@export var reference_music: AudioStreamPlayer

var _music_time: float = 0.0
var _music_fade_tween: Tween

func resume() -> void :
	if _music_fade_tween != null:
		_music_fade_tween.kill()

	_music_time = reference_music.get_playback_position()
	reference_music.stop()

	release_focus()
	get_tree().paused = false
	paused = false

func restart() -> void :
	release_focus()
	SceneChanger.change_to(get_tree().current_scene.scene_file_path, &"hypno")

func exit() -> void :
	LullabyGameoverModule.has_died = false
	release_focus()
	SceneChanger.change_to("res://rooms/env_collector_shop.tscn", &"hypno", true)

func show_credits() -> void :
	credits_shown = not credits_shown

func _input(event: InputEvent) -> void :
	if not active:
		return

	if not event.is_action_pressed("funkin_pause"):
		return

	var tree: SceneTree = get_tree()
	if tree.paused:
		return

	tree.paused = true
	paused = true

	if level != null:
		pass



	reference_music.volume_linear = 0.0
	reference_music.play(_music_time)

	_music_fade_tween = reference_music.create_tween()
	_music_fade_tween.tween_property(reference_music, "volume_linear", 0.3, 10.0)
	_music_fade_tween.play()

	if not level or level.metadata.title.to_lower() != "chimera":
		return

	var allow_exit: bool = true
	if SaveData.get_flag(&"chimera_2nd_phase_first") and not SaveData.get_flag(&"chimera_beaten"):
		allow_exit = false

	exit_button.visible = allow_exit

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
