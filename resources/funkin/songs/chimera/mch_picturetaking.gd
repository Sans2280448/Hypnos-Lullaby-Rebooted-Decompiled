@tool
extends Node
class_name PictureTakingController

@export_tool_button("Start PictureTaking") var start_playtest = start_mechanic
@export_tool_button("Stop PictureTaking") var stop_playtesting = stop_mechanic

@export var autoplay: bool = false
@export var autoplay_picture_time: float = 0.5

@export_group("Input")
@export var input_map: StringName = &"lullaby_special"

@export_group("References")
@export var animation_player: AnimationPlayer
@export var spotlight: SpotLight3D

@export_group("Flash")
@export var flash_energy: float = 16.0
@export var normal_energy: float = 0.0
@export var flash_time: float = 0.06
@export var fade_out_time: float = 0.18

var mechanic_enabled: bool = false
var _flash_tween: Tween

var _autoplay_time_passed: float = 0.0

func start_mechanic() -> void :
	mechanic_enabled = true
	kill_flash_tween()

	if animation_player != null:
		animation_player.pause()

	if spotlight != null:
		spotlight.visible = true
		spotlight.light_energy = normal_energy

	print("Started picture taking")


func stop_mechanic(turn_off_spotlight: bool = true) -> void :
	mechanic_enabled = false
	kill_flash_tween()

	if animation_player != null:
		animation_player.play()

	if spotlight != null and turn_off_spotlight:
		spotlight.light_energy = normal_energy
		spotlight.visible = false

	print("Stopped picture taking")

func _process(delta: float) -> void :
	if not autoplay or not mechanic_enabled:
		return

	_autoplay_time_passed += delta
	if _autoplay_time_passed < autoplay_picture_time:
		return


	trigger_flash_and_continue()

func _input(event: InputEvent) -> void :
	if !mechanic_enabled:
		return

	if event.is_action_pressed(input_map):
		trigger_flash_and_continue()


func trigger_flash_and_continue() -> void :
	stop_mechanic(false)
	flash_spotlight()


func flash_spotlight() -> void :
	if spotlight == null:
		return

	kill_flash_tween()

	spotlight.visible = true
	spotlight.light_energy = flash_energy

	_flash_tween = create_tween()
	_flash_tween.tween_interval(flash_time)
	_flash_tween.tween_property(spotlight, "light_energy", normal_energy, fade_out_time)
	_flash_tween.tween_callback( func():
		spotlight.visible = false
	)


func kill_flash_tween() -> void :
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	_flash_tween = null
