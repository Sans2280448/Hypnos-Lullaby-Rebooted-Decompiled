class_name LullabyFPSDisplay extends Node

enum CurrentState
{
	NONE = 0, 
	BASIC = 1, 
	ADVANCED = 2
}

var current_state: CurrentState = CurrentState.NONE

@export var container: Control

@export_group("FPS", "fps_")
@export var fps_average_counter: Label
@export var fps_low_counter: Label
@export var fps_high_counter: Label

@export var game_name_label: Label
@export var game_version_label: Label
@export var game_type_label: Label
@export var godot_version_label: Label
@export var debug_only_section: Control
@export var ram_label: Label
@export var vram_label: Label

var _fps_tracker: PackedInt32Array
var _fps_index: int = 0
var _disable_quick_restart: bool = false

func _ready() -> void :
	game_name_label.text = ProjectSettings.get("application/config/name")
	game_version_label.text = ProjectSettings.get("application/config/version")
	game_type_label.text = "[%s]" % ("Editor" if Engine.is_editor_hint() else ("Debug" if OS.is_debug_build() else "Release"))

	var godot_version: Dictionary = Engine.get_version_info()
	godot_version_label.text = "%s" % [godot_version["string"]]

	_fps_tracker.resize(60)
	_fps_tracker.fill(0)

	update_visibility()

func _process(delta: float) -> void :
	if current_state == CurrentState.NONE:
		return

	var tracker_size: int = _fps_tracker.size()
	_fps_index = (_fps_index + 1) % tracker_size
	_fps_tracker[_fps_index] = floori(1.0 / delta);

	var average: int = 0
	var low: int = _fps_tracker[0]
	var high: int = 0
	for i in tracker_size:
		var current_value: int = _fps_tracker[i]
		average += _fps_tracker[i]

		if current_value < low:
			low = current_value

		if current_value > high:
			high = current_value

	average = floori(float(average) / tracker_size)

	fps_average_counter.text = str(average)
	fps_low_counter.text = str(low)
	fps_high_counter.text = str(high)

	if current_state < CurrentState.ADVANCED:
		return

	ram_label.text = "%s / %s" % [to_memory_format(OS.get_static_memory_usage()), to_memory_format(OS.get_static_memory_peak_usage())]
	vram_label.text = "%s" % [to_memory_format(floori(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)))]

func update_visibility() -> void :
	match current_state:
		CurrentState.NONE:
			container.visible = false
			debug_only_section.visible = false
		CurrentState.BASIC:
			container.visible = true
			debug_only_section.visible = false
		CurrentState.ADVANCED:
			container.visible = true
			debug_only_section.visible = true

func _input(event: InputEvent) -> void :
	if event.is_action_pressed("quick_restart") and get_tree().current_scene is RubiconLevel and not _disable_quick_restart:
		SceneChanger.change_to(get_tree().current_scene.scene_file_path, &"hypno")

	if event.is_echo() or not event.is_action_pressed(&"debug_toggle"):
		return
	var limit: int = 3 if OS.is_debug_build() else 2
	current_state = ((current_state + 1) % limit) as CurrentState
	update_visibility()

func to_memory_format(mem: int) -> String:
	if mem >= 1073741824:
		return "%s GB" % snappedf(mem / 1024.0 / 1024.0 / 1024.0, 0.01)
	elif mem >= 1048576:
		return "%s MB" % snappedf(mem / 1024.0 / 1024.0, 0.01)
	elif mem >= 1024:
		return "%s KB" % snappedf(mem / 1024.0, 0.01)
	else:
		return "%s B"
