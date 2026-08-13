@tool
extends Button

enum ResultTypes{
	SPRITEFRAMES, 
	ANIMATIONLIBRARY, 
}

@export var result_type: ResultTypes
@export var line_edit: LineEdit
var file_dialog: EditorFileDialog

func _ready() -> void :
	if !Engine.is_editor_hint():
		return

	icon = EditorInterface.get_base_control().get_theme_icon(&"Folder", &"EditorIcons")
	connect(&"pressed", make_dialog)

func make_dialog() -> void :
	file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_FILE

	var screen_size: Vector2 = DisplayServer.screen_get_size()
	file_dialog.size = Vector2(screen_size.x / 2, screen_size.y / 1.5)

	file_dialog.initial_position = Window.WindowInitialPosition.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	file_dialog.connect(&"file_selected", spriteframes_selected if result_type == ResultTypes.SPRITEFRAMES else animation_library_selected)
	file_dialog.filters = ["*.tres", "*.res"]
	file_dialog.title = "Select Sprite Frames" if result_type == ResultTypes.SPRITEFRAMES else "Select Animation Library"
	add_child(file_dialog)
	file_dialog.popup_centered()


func spriteframes_selected(path: String) -> void :
	if load(path) is SpriteFrames:
		line_edit.text = path
		line_edit.text_changed.emit(path)
		file_dialog.queue_free()
	else:
		file_dialog.popup_centered()

func animation_library_selected(path: String) -> void :
	if load(path) is AnimationLibrary:
		line_edit.text = path
		line_edit.text_changed.emit(path)
		file_dialog.queue_free()
	else:
		file_dialog.popup_centered()

func kill_dialog() -> void :
	file_dialog.queue_free()

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			icon = null
