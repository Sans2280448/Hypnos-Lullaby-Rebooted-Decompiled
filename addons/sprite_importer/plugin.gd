@tool
extends EditorPlugin

static var importer_scene: Control
var dock: EditorDock

func _enter_tree() -> void :
	ImportUtils.addon_path = get_script().resource_path.get_base_dir() + "/"
	importer_scene = load(ImportUtils.addon_path + "PluginScene.tscn").instantiate()

	dock = EditorDock.new()
	dock.title = _get_plugin_name()
	dock.icon_name = &"SpriteFrames"
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL | EditorDock.DOCK_LAYOUT_HORIZONTAL
	dock.connect(&"closed", _close_dock)
	dock.add_child(importer_scene)
	add_dock(dock)

func _exit_tree() -> void :
	remove_dock(dock)
	importer_scene.queue_free()

func _get_plugin_name():
	return "Sprite Importer"

func _close_dock() -> void :
	EditorInterface.set_plugin_enabled("sprite_importer", false)
