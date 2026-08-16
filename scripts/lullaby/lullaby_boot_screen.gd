class_name LullabyBootScreen extends Node

@export_file("*.tscn", "*.scn") var next_scene_path: String
@export_file("*.tscn", "*.scn") var debug_scene_path: String
@export_file("*.tscn", "*.scn") var fuckno_scene_path: String
@export_file("*.tscn", "*.scn") var warning_scene_path: String
@export_file("*.tscn", "*.scn") var first_boot_scene_path: String
@export_file("*.tscn", "*.scn") var shitty_gpu_scene_path: String
@export_file("*.tscn", "*.scn") var chimera_path: String

var _go_to_debug: bool = false

func _on_timer_end() -> void :
	var tree: SceneTree = get_tree()

	if _is_on_ANGLE() and not (SaveData.has_meta(&"angle_seen") and SaveData.get_meta(&"angle_seen")):
		tree.change_scene_to_file(shitty_gpu_scene_path)
		return

	if _go_to_debug:
		Debugger.can_go_to_debug = true
		tree.change_scene_to_file(debug_scene_path)
		return

	if SaveData.get_flag(&"chimera_2nd_phase_first") and not SaveData.get_flag(&"chimera_beaten"):
		SceneChanger.change_to(chimera_path, &"hypno")
		return

	if SaveData.misc_fuckno and not SaveData.get_flag(&"fuckno_seen"):
		tree.change_scene_to_file(fuckno_scene_path)
		return

	Debugger.can_go_to_debug = true
	if not SaveData.get_flag(&"warning_seen"):
		tree.change_scene_to_file(warning_scene_path)
		return

	if not SaveData.get_flag(&"first_boot_seen"):
		tree.change_scene_to_file(first_boot_scene_path)
		return

	SceneChanger.change_to(next_scene_path, &"hypno")

func _input(event: InputEvent) -> void :
	if event is not InputEventKey:
		return

	var key: InputEventKey = event
	if key.keycode == KEY_F12 and key.is_command_or_control_pressed():
		_go_to_debug = true

func _is_on_ANGLE() -> bool:
	var driver: String = RenderingServer.get_video_adapter_name().to_upper()
	return driver.contains("ANGLE") or driver.contains("D3D11") or driver.contains("DirectX")
