class_name LullabyGlobalDebugger extends Node

const DebugMenu: String = "res://rooms/scn_debug_select.tscn"
const LullabySettingsMenu = preload("uid://c4ggprtkkkkpe")

@export var fps_display: LullabyFPSDisplay
@export var settings: LullabySettingsMenu

var can_go_to_debug: bool = false

func _input(event: InputEvent) -> void :
	if event is not InputEventKey:
		return

	var key: InputEventKey = event
	var settings_combo: bool = key.keycode == Key.KEY_S and key.is_command_or_control_pressed() and key.alt_pressed
	var debug_combo: bool = key.keycode == Key.KEY_F12 and key.is_command_or_control_pressed()

	if settings_combo and not settings.visible:
		settings.open()

	if debug_combo and can_go_to_debug and get_tree().current_scene.scene_file_path != DebugMenu and not SceneChanger._is_loading:
		SceneChanger.change_to(DebugMenu, &"default")
