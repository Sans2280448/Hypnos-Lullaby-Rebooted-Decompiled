@tool
extends Window

@export var chart_type_label: Label
@export var file_path: LineEdit
@export var folder_button: Button
@export var accept_button: Button
@export var file_dialog: FileDialog

var _chart_type: String

signal accepted(file: String, skipped: bool)

func _enter_tree() -> void :
	chart_type_label.text = "%s metadata file:" % [_chart_type if !_chart_type.is_empty() else "ENGINE"]
	folder_button.icon = null
	if Engine.is_editor_hint():
		folder_button.icon = EditorInterface.get_editor_theme().get_icon(&"Folder", &"EditorIcons")
	show()

func path_updated(new_path: String) -> void :
	if new_path.ends_with(".json") and FileAccess.file_exists(new_path):
		accept_button.disabled = false
		return
	accept_button.disabled = true

func _folder_button() -> void :
	file_dialog.show()

func file_selected(path: String) -> void :
	file_path.text = path
	path_updated(path)

func accept() -> void :
	accepted.emit(file_path.text, false)
	queue_free()

func skip() -> void :
	accepted.emit("", true)
	queue_free()

func cancel() -> void :
	accepted.emit("", false)
	queue_free()
