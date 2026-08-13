@tool
extends Control

@export_dir var tabs_path: String
@export var tab_container: TabContainer

func _ready() -> void :
	if ImportUtils.addon_path.is_empty():
		ImportUtils.addon_path = get_script().resource_path.get_base_dir() + "/"

	if tabs_path.is_empty() or !DirAccess.dir_exists_absolute(tabs_path):
		tabs_path = ImportUtils.addon_path + "tabs"

	var tabs: PackedStringArray = DirAccess.get_files_at(tabs_path)
	for tab: String in tabs:
		if tab.get_extension() != "tscn":
			continue

		var tab_path: String = tabs_path + "/" + tab
		var new_tab: ImporterTab = load(tab_path).instantiate() as ImporterTab







		tab_container.add_child(new_tab)



		if tab.to_lower().begins_with("sparrow"):
			tab_container.move_child(new_tab, 0)
			tab_container.current_tab = 0
