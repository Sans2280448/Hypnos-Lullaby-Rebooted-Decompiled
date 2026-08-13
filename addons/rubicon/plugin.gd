@tool
extends EditorPlugin

const CREATE_CONTEXT_MENU_PLUGIN = preload("res://addons/rubicon/scripts/create_context_menu_plugin.gd")
var _instance: EditorContextMenuPlugin

var playtesting_level: bool = false:
	set(value):
		playtesting_level = value
		RubiconLevelNoteController.is_playtesting = value
var playtest_checkbox: CheckBox

func _enter_tree() -> void :
	add_project_setting("rubicon/defaults/note_database", TYPE_STRING, PROPERTY_HINT_FILE, "*.tres,*.res", "res://note_database.tres")
	add_project_setting("rubicon/defaults/character_template", TYPE_STRING, PROPERTY_HINT_FILE, "*.tscn", "")

	var note_database_path: String = ProjectSettings.get_setting("rubicon/defaults/note_database")
	if not ResourceLoader.exists(note_database_path):
		ResourceSaver.save(RubiconLevelNoteDatabase.new(), note_database_path)

	_instance = CREATE_CONTEXT_MENU_PLUGIN.new()
	_instance.connect("popup_menu", _popup_menu)

	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM_CREATE, _instance)

	playtest_checkbox = CheckBox.new()
	playtest_checkbox.text = "Playtest Level"
	playtest_checkbox.connect("pressed", playtest_checked)

	connect("scene_changed", _scene_changed)

func _exit_tree() -> void :
	playtest_checkbox.queue_free()
	remove_context_menu_plugin(_instance)

func add_project_setting(name: String, type: Variant.Type, hint: PropertyHint, hint_string: String = "", default_value: Variant = null, basic: bool = true) -> void :
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)

	ProjectSettings.add_property_info({
		"name": name, 
		"type": type, 
		"hint": hint, 
		"hint_string": hint_string
	})

	ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.set_as_basic(name, basic)

func _popup_menu(paths: PackedStringArray) -> void :
	var scene_icon: Texture2D = EditorInterface.get_editor_theme().get_icon(&"PackedScene", &"EditorIcons")
	var create_character_callable: Callable = Callable(self, "_create_popup").bind(_instance.CREATE_CHARACTER_POPUP, _instance._create_simple_character)

	_instance.add_context_menu_item("Character...", create_character_callable, scene_icon)

func _create_popup(paths: PackedStringArray, popup_scene: PackedScene, confirm_call: Callable) -> void :
	var screen_scale: float = DisplayServer.screen_get_scale()
	var instance: ConfirmationDialog = popup_scene.instantiate()
	instance.base_path = paths[0]
	instance.content_scale_factor = screen_scale
	add_child(instance)
	instance.popup_centered(instance.size * DisplayServer.screen_get_scale())
	instance.confirmed.connect( func(): confirm_call.call(instance.base_path, instance._name, instance._selected_type, instance.sprite_frames_path.text, instance.animation_library_path.text))

func _scene_changed(scene_root: Node) -> void :
	if scene_root is RubiconLevel:
		add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, playtest_checkbox)
	else:
		disable_playtesting()
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, playtest_checkbox)

func playtest_checked() -> void :
	if get_tree() != null and !(get_tree().edited_scene_root is RubiconLevel):
		return

	playtesting_level = playtest_checkbox.button_pressed

func disable_playtesting() -> void :
	playtesting_level = false
	playtest_checkbox.set_pressed_no_signal(false)
	EditorInterface.get_editor_viewport_2d().gui_disable_input = false

func _handles(object: Object) -> bool:
	if object is Node:
		return true
	return false

func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if event is InputEventKey and playtesting_level:
		EditorInterface.get_editor_viewport_2d().gui_disable_input = false
		EditorInterface.get_editor_viewport_2d().push_input(event)
		return true
	return false
