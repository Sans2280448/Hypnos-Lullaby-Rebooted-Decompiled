class_name LullabySettings extends Node

const SAVE_PATH: String = "user://settings.ini"

const MASTER_VOLUME_BUS: int = 0
const MUSIC_VOLUME_BUS: int = 1
const SOUND_EFFECTS_VOLUME_BUS: int = 2
const VOCALS_VOLUME_BUS: int = 3

const VERSION_MAJOR: int = 1
const VERSION_MINOR: int = 0
const VERSION_PATCH: int = 0
const VERSION_BUILD: int = 0

const PRESET_HIGH: LullabyQualityPreset = preload("res://resources/quality_presets/qol_high.tres")
const PRESET_MEDIUM: LullabyQualityPreset = preload("res://resources/quality_presets/qol_medium.tres")
const PRESET_LOW: LullabyQualityPreset = preload("res://resources/quality_presets/qol_low.tres")

const DEFAULT_GAME_INPUTS: RubiconLevelNoteInputMap = preload("res://addons/rubicon_mania/resources/default_input_map.tres")
const INPUT_EXCLUSIONS: Array[StringName] = [
	&"ui_accept", 
	&"ui_select", 
	&"ui_cancel", 
	&"ui_close_dialog", 
	&"ui_close_dialog.macos", 
	&"ui_focus_next", 
	&"ui_focus_prev", 
	&"ui_left", 
	&"ui_right", 
	&"ui_up", 
	&"ui_down", 
	&"ui_page_up", 
	&"ui_page_down", 
	&"ui_home", 
	&"ui_end", 
	&"ui_accessibility_drag_and_drop", 
	&"ui_cut", 
	&"ui_copy", 
	&"ui_focus_mode", 
	&"ui_paste", 
	&"ui_undo", 
	&"ui_redo", 
	&"ui_text_completion_query", 
	&"ui_text_completion_accept", 
	&"ui_text_completion_replace", 
	&"ui_text_newline", 
	&"ui_text_newline_blank", 
	&"ui_text_newline_above", 
	&"ui_text_indent", 
	&"ui_text_dedent", 
	&"ui_text_backspace", 
	&"ui_text_backspace_word", 
	&"ui_text_backspace_word.macos", 
	&"ui_text_backspace_all_to_left", 
	&"ui_text_backspace_all_to_left.macos", 
	&"ui_text_delete", 
	&"ui_text_delete_word", 
	&"ui_text_delete_word.macos", 
	&"ui_text_delete_all_to_right", 
	&"ui_text_delete_all_to_right.macos", 
	&"ui_text_caret_left", 
	&"ui_text_caret_word_left", 
	&"ui_text_caret_word_left.macos", 
	&"ui_text_caret_right", 
	&"ui_text_caret_word_right", 
	&"ui_text_caret_word_right.macos", 
	&"ui_text_caret_up", 
	&"ui_text_caret_down", 
	&"ui_text_caret_line_start", 
	&"ui_text_caret_line_start.macos", 
	&"ui_text_caret_line_end", 
	&"ui_text_caret_line_end.macos", 
	&"ui_text_caret_page_up", 
	&"ui_text_caret_page_down", 
	&"ui_text_caret_document_start", 
	&"ui_text_caret_document_start.macos", 
	&"ui_text_caret_document_end", 
	&"ui_text_caret_document_end.macos", 
	&"ui_text_caret_add_below", 
	&"ui_text_caret_add_below.macos", 
	&"ui_text_caret_add_above", 
	&"ui_text_caret_add_above.macos", 
	&"ui_text_scroll_up", 
	&"ui_text_scroll_up.macos", 
	&"ui_text_scroll_down", 
	&"ui_text_scroll_down.macos", 
	&"ui_text_select_all", 
	&"ui_text_select_word_under_caret", 
	&"ui_text_select_word_under_caret.macos", 
	&"ui_text_add_selection_for_next_occurrence", 
	&"ui_text_skip_selection_for_next_occurrence", 
	&"ui_text_clear_carets_and_selection", 
	&"ui_text_toggle_insert_mode", 
	&"ui_menu", 
	&"ui_text_submit", 
	&"ui_unicode_start", 
	&"ui_graph_duplicate", 
	&"ui_graph_delete", 
	&"ui_graph_follow_left", 
	&"ui_graph_follow_left.macos", 
	&"ui_graph_follow_right", 
	&"ui_graph_follow_right.macos", 
	&"ui_filedialog_delete", 
	&"ui_filedialog_up_one_level", 
	&"ui_filedialog_refresh", 
	&"ui_filedialog_show_hidden", 
	&"ui_filedialog_find", 
	&"ui_filedialog_focus_path", 
	&"ui_filedialog_focus_path.macos", 
	&"ui_swap_input_direction", 
	&"ui_colorpicker_delete_preset"
]

signal applied
signal volume_changed(bus: StringName, value: float)

var lullaby_version: int = _encode_version_number(VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH, VERSION_BUILD)
var lullaby_baby_mode: bool = false
var lullaby_bumpscosity: float = 1.0

var display_window_mode: Window.Mode = Window.Mode.MODE_FULLSCREEN
var display_resolution: Vector2i = Vector2i(1366, 768)
var display_vsync: DisplayServer.VSyncMode = DisplayServer.VSyncMode.VSYNC_DISABLED
var display_target_fps: int = 60

var graphics_scaling_mode: Viewport.Scaling3DMode = Viewport.Scaling3DMode.SCALING_3D_MODE_BILINEAR
var graphics_render_scale: float = 1.0
var graphics_fsr_sharpness: float = 1.0
var graphics_positional_shadow_atlas_size: int = 4096
var graphics_positional_shadow_filter_quality: int = 2
var graphics_screen_space_aa_quality: Viewport.ScreenSpaceAA = Viewport.ScreenSpaceAA.SCREEN_SPACE_AA_SMAA
var graphics_msaa_3d_quality: Viewport.MSAA = Viewport.MSAA.MSAA_4X
var graphics_ssao: bool = true
var graphics_ssil: bool = true

enum PostProcessing{
	NONE = 0, 
	LOW = 1, 
	HIGH = 2
}

var graphics_post_processing: PostProcessing = PostProcessing.HIGH

var audio_master_volume: float = 1.2:
	set(v):
		v = clampf(v, 0, 1.2)
		if audio_master_volume != v:
			audio_master_volume = v
			volume_changed.emit(&"Master", v)

var audio_music_volume: float = 1.0:
	set(v):
		v = clampf(v, 0, 1.0)
		if audio_music_volume != v:
			audio_music_volume = v
			volume_changed.emit(&"Music", v)

var audio_sfx_volume: float = 1.0:
	set(v):
		v = clampf(v, 0, 1.0)
		if audio_sfx_volume != v:
			audio_sfx_volume = v
			volume_changed.emit(&"SoundEffects", v)

var audio_vox_volume: float = 1.0:
	set(v):
		v = clampf(v, 0, 1.0)
		if audio_vox_volume != v:
			audio_vox_volume = v
			volume_changed.emit(&"Voice", v)

var game_offset: float = 0.0
var game_visual_offset: float = 0.0
var game_flashing_lights: bool = true
var game_autoplay: bool = false
var game_speed_multiplier: float = 1.0
var game_downscroll: bool = false
var game_ghost_tapping: bool = true
var game_centered: bool = false

var input_game: Dictionary[StringName, Array] = {}
var input_map: Dictionary[StringName, Array] = {}

var _level_note_inputs: RubiconLevelNoteInputMap = RubiconLevelNoteInputMap.new()

func _ready() -> void :
	if load_from(SAVE_PATH) == ERR_FILE_NOT_FOUND:
		reset_input_map()
		save(SAVE_PATH)

	apply_settings()

func _input(event: InputEvent) -> void :
	if event.is_pressed() and event.is_action(&"fullscreen_toggle"):
		var window: = get_window()

		if display_window_mode != Window.MODE_FULLSCREEN:
			display_window_mode = Window.MODE_FULLSCREEN
		else:
			display_window_mode = Window.MODE_WINDOWED

		save(SAVE_PATH)

		window.mode = display_window_mode

		if window.mode == Window.MODE_WINDOWED:
			window.size = display_resolution
			window.move_to_center()

func get_level_note_inputs() -> RubiconLevelNoteInputMap:
	return _level_note_inputs

func get_quality_preset() -> LullabyQualityPreset:
	if PRESET_HIGH.is_matching(self):
		return PRESET_HIGH
	elif PRESET_MEDIUM.is_matching(self):
		return PRESET_MEDIUM
	elif PRESET_LOW.is_matching(self):
		return PRESET_LOW

	return null

func apply_settings() -> void :
	var window: Window = get_window()

	window.mode = display_window_mode
	if window.mode != Window.MODE_FULLSCREEN:
		window.size = display_resolution

	if window.mode == Window.MODE_WINDOWED:
		window.move_to_center()

	DisplayServer.window_set_vsync_mode(display_vsync, window.get_window_id())
	Engine.max_fps = display_target_fps

	window.scaling_3d_mode = graphics_scaling_mode
	window.scaling_3d_scale = graphics_render_scale
	window.fsr_sharpness = graphics_fsr_sharpness
	window.positional_shadow_atlas_size = graphics_positional_shadow_atlas_size
	ProjectSettings.set("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", graphics_positional_shadow_filter_quality)

	window.msaa_3d = graphics_msaa_3d_quality
	window.screen_space_aa = graphics_screen_space_aa_quality

	AudioServer.set_bus_volume_linear(MASTER_VOLUME_BUS, audio_master_volume)
	AudioServer.set_bus_volume_linear(MUSIC_VOLUME_BUS, audio_music_volume)
	AudioServer.set_bus_volume_linear(SOUND_EFFECTS_VOLUME_BUS, audio_sfx_volume)

	_level_note_inputs.inputs.clear()
	for action_name: StringName in input_game:
		for input_event: InputEvent in input_game[action_name]:
			_level_note_inputs.inputs[input_event] = action_name

	for action_name: StringName in input_map:
		InputMap.action_erase_events(action_name)
		for input_event: InputEvent in input_map[action_name]:
			InputMap.action_add_event(action_name, input_event)

	applied.emit()

func get_input_name(action: StringName) -> String:
	if not input_map.has(action):
		return ""

	for event in input_map[action]:
		return event.as_text()

	return ""

func reset_input_map() -> void :
	input_map.clear()
	input_game.clear()

	for input_action: InputEvent in DEFAULT_GAME_INPUTS.inputs:
		var value: StringName = DEFAULT_GAME_INPUTS.inputs[input_action]

		if not input_game.has(value):
			input_game[value] = Array()

		input_game[value].append(input_action)

	InputMap.load_from_project_settings()
	for action_name: StringName in InputMap.get_actions():
		if INPUT_EXCLUSIONS.has(action_name):
			continue

		var input_events: Array[InputEvent] = InputMap.action_get_events(action_name)
		input_map[action_name] = input_events

func save(path: String = SAVE_PATH) -> void :
	var config: ConfigFile = ConfigFile.new()

	var property_list: Array = get_script().get_script_property_list()
	for property in property_list:
		var property_name: String = property["name"]
		if !property_name.get_extension().is_empty() or property_name.begins_with("_"):
			continue

		var section: String = property_name.substr(0, property_name.find("_"))
		var setting: String = property_name.substr(property_name.find("_") + 1)
		config.set_value(section, setting, get(property_name))

	var err: Error = config.save(path)
	if err != OK:
		ErrorHandler.show_warning("Settings could not be flushed to disk.", err)

func load_from(path: String = SAVE_PATH) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(path)

	if err != OK:
		return err

	reset_input_map()

	var skip_properties: Array[StringName] = [&"lullaby_version"]
	match config.get_value(&"lullaby", &"version", 0):
		0:
			skip_properties.append(&"lullaby_show_pendulum_on_screen")
			skip_properties.append(&"graphics_preset")

			skip_properties.append(&"input_map")
			var map_input: Dictionary[StringName, Array] = config.get_value(&"input", &"map")
			if input_map.has(&"lullaby_pendulum"):
				map_input[&"lullaby_special"] = map_input[&"lullaby_pendulum"]
				map_input.erase(&"lullaby_pendulum")

			for input in map_input:
				input_map[input] = map_input[input]

			save(path)

		16777216:
			pass

	var last_section: StringName
	var last_key: StringName
	while err == OK:
		for section in config.get_sections():
			last_section = section
			for key in config.get_section_keys(section):
				last_key = key

				var property_name: StringName = "%s_%s" % [section, key]
				if skip_properties.has(property_name):
					continue

				match property_name:
					&"input_map":
						var map_input: Dictionary[StringName, Array] = config.get_value(&"input", &"map")
						for input in map_input:
							input_map[input] = map_input[input]

						continue

				if property_name in self:
					set("%s_%s" % [section, key], config.get_value(section, key))
				else:
					ErrorHandler.show_warning("Tried to load setting \"%s\", but it does not exist." % [property_name], ERR_CANT_RESOLVE)

		return OK

	ErrorHandler.show_warning("Settings were only partially loaded. Stopped at [%s] %s" % [last_section, last_key], ERR_PARSE_ERROR)
	return err

func _encode_version_number(major: int, minor: int, patch: int, build: int) -> int:
	return (major << 24) | (minor << 16) | (patch << 8) | build

func _decode_version_number(raw: int) -> Array[int]:
	var version: Array[int] = []
	version.resize(4)
	version[0] = (raw & 4278190080) >> 24
	version[1] = (raw & 16711680) >> 16
	version[2] = (raw & 65280) >> 8
	version[3] = raw & 255

	return version
