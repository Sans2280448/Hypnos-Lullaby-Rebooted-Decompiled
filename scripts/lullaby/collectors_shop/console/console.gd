class_name Console
extends Control

signal boot_finished
signal play_sound(filename: String)

static var boot_enabled: bool = false:
	set(v):
		if boot_enabled != v:
			boot_enabled = v
			SaveData.set_flag(&"console_on", v)
			SaveData.save()

static var has_booted: bool = false

@export var shop: CollectorShop
@export var tab_container: TabContainer
@export var startup_sound: AudioStreamPlayer
@export var other_sounds: AudioStreamPlayer

@export var background_anim: AnimationPlayer
@export var sequences: ShopSequences

@onready var main_animation_player: AnimationPlayer
@onready var music: AudioStreamPlayer = %Music
@onready var music_fader: AnimationPlayer = %MusicFader

@export var focus_right_area: FocusArea3D

var in_submenu: bool = false
var backout_focus: Button

var in_home: bool
var time: float = 0.0
var booting: bool = false
var focused: bool = false


func _ready() -> void :
	main_animation_player = $AnimationPlayer
	boot(false)

	if background_anim:
		background_anim.animation_finished.connect(_on_background_anim_finished)

	other_sounds.volume_linear = 0.0
	music.volume_linear = 0.0


func _process(_delta: float) -> void :
	if (
		booting and 
		main_animation_player.is_playing() and 
		main_animation_player.current_animation_position >= 13.34
	):
		booting = false
		boot_finished.emit()


func _input(event: InputEvent) -> void :
	if event.is_action_pressed(&"ui_cancel"):
		back_out()


func back_out() -> void :
	if not focused:
		return
	if booting:
		return

	play_sound.emit("sfx_soulroom_back")

	if in_submenu:
		in_submenu = false
		backout_focus.grab_focus()
		Settings.apply_settings()
		Settings.save()
	else:
		if tab_container.current_tab == 0 and sequences:
			music_fader.play(&"fade_out")
			sequences.animation_player.play(&"focus_right")
			focus_right_area.can_interact = true
			focus_right_area.register_trigger()

			focused = false
		else:
			tab_container.change_tab(0)


func boot(with_intro: bool) -> void :
	if with_intro:
		main_animation_player.play(&"RESET")
		main_animation_player.seek(0.0, true)
		main_animation_player.play(&"collector intro")
		main_animation_player.seek(0.0, true)
	else:
		startup_sound.volume_linear = 0.0

		main_animation_player.play(&"bg_startup")
		main_animation_player.seek(13.43, true)

		background_anim.play(&"Scene")
		background_anim.seek(13.43, true)
		background_anim.queue(&"loop")


func _on_background_anim_finished(anim_name: StringName) -> void :
	if anim_name == &"Scene":
		background_anim.play(&"loop")
