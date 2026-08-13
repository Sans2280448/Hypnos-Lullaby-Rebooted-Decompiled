extends Node2D


@export_file("*.tscn") var scene_path: String

@export var loading_screen: StringName = &"hypno"

@export var animation_player: AnimationPlayer
@export var retry_animation: StringName = &"retry"

var transitioning: bool = false


func _ready() -> void :
	var info: = LullabyGameoverModule.last_song_info
	if info.get(&"skip_intro", false):
		animation_player.play(&"end_game_over")
	else:
		animation_player.play(&"game_over")


func _input(event: InputEvent) -> void :
	if transitioning:
		return
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	if animation_player.current_animation:
		return

	if event.is_action(&"ui_accept") and animation_player:
		transitioning = true
		animation_player.animation_finished.connect(transition_to_game, CONNECT_ONE_SHOT)
		animation_player.play(retry_animation)


func transition_to_game(_anim: StringName) -> void :
	if scene_path.is_empty():
		scene_path = LullabyGameoverModule.last_song_path

	if scene_path.is_empty():
		transitioning = false
		animation_player.play(&"RESET")
		return

	SceneChanger.change_to(scene_path, loading_screen)
