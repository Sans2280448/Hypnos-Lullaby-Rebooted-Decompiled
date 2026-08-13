extends Node

var Flashing_Displayed = false
@export var press_sound: AudioStreamPlayer
@export var kill_sound: AudioStreamPlayer
@export var black: ColorRect
@export var focus_first: Control

@onready var yes_button: Button = %YesButton
@onready var no_button: Button = %NoButton

@onready var long_tab: TextureRect = %"Warning Long Tab"
@onready var warning_text: RichTextLabel = %"Warning Text"

@onready var warning_header: TextureRect = %WarningHeader
@onready var transition_player: AnimationPlayer = %Tranisition
@onready var flash_player: AnimationPlayer = %FlashOptions

@export var in_flashing_warning: bool = false

func _ready() -> void :
	transition_player.play("FadeOut")

func _process(delta: float) -> void :
	var time: float = (Time.get_ticks_msec() / 1000.0) * 0.75;

	no_button.position.y = 200 + (sin(time) * 4.0)
	yes_button.position.y = 200 + (sin(time + 1.0) * 4.0)

	long_tab.position.y = -190 + (sin(time - 0.5) * -4)
	warning_text.position.y = -160 + (sin(time - 0.5) * -4)

	warning_header.position.y = -400 + (sin(time - 0.7) * -4)

func go_to_title():
	press_sound.play()
	await get_tree().create_timer(0.2).timeout

	SaveData.set_flag(&"warning_seen", true)
	get_tree().change_scene_to_file("res://rooms/scn_boot.tscn")

func _on_no_button_button_down() -> void :
	if not in_flashing_warning:
		kill_sound.play()
		await get_tree().create_timer(0.15).timeout
		get_tree().quit()
	else:
		set_flashing_lights(false)
		go_to_title()

func _on_yes_button_button_down() -> void :
	if not in_flashing_warning:
		flash_player.play("TextFadeOut")
		press_sound.play()
		Flashing_Displayed = true
	else:
		set_flashing_lights(true)
		go_to_title()

func set_flashing_lights(on: bool):
	Settings.set("game_flashing_lights", on)
	Settings.apply_settings()
	Settings.save()
