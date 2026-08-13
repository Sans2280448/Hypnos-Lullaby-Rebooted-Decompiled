class_name GameIntro
extends Control

static var skip_intro: = false

@export var root_anim_player: AnimationPlayer
@export var camera_anim_player: AnimationPlayer
@export var door_button: Button

@onready var intro_player: AudioStreamPlayer = %IntroPlayer
@onready var initial_timer: Timer = %InitialTimer

@export var intro_skipped: bool = false

func _ready() -> void :
	if skip_intro:
		initial_timer.stop()

		root_anim_player.play(&"intro")
		root_anim_player.seek(20.0, true)

		var interactive: AudioStreamInteractive = intro_player.stream
		interactive.initial_clip = 1
		intro_player.play()


func _input(event: InputEvent) -> void :

	if event.is_action(&"ui_accept") and event.is_pressed():
		if root_anim_player.current_animation == &"intro" and not intro_skipped:
			skipintro()

	if ( not door_button) or ( not door_button.visible):
		return

	if event.is_action(&"ui_accept") and event.is_pressed():
		if door_button.visible:
			click_door()

func skipintro() -> void :
	intro_skipped = true
	initial_timer.stop()

	root_anim_player.play(&"intro")
	root_anim_player.seek(9.9, true)

	var interactive: AudioStreamInteractive = intro_player.stream
	interactive.initial_clip = 1
	intro_player.play()

func click_door() -> void :
	root_anim_player.pause()
	camera_anim_player.play(&"go_in")


	if SaveData.get_flag(&"splash_seen"):
		SaveData.set_flag(&"splash_seen", true)
		SaveData.save()


func go_into_shop() -> void :
	SceneChanger.change_to("uid://bqkjiwokrcvo", &"hypno", true)


func _on_initial_timer_timeout() -> void :
	root_anim_player.play(&"intro")


func _on_camera_animation_finished(anim_name: StringName) -> void :
	if anim_name == &"go_in":
		go_into_shop()
