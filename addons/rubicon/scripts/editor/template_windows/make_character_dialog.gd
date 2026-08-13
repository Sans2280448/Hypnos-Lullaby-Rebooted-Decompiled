@tool
extends ConfirmationDialog

@export var path_line_edit: LineEdit
@export var base_path_label: Label
@export var path_validator: Label
var _name: String:
	get():
		return path_line_edit.text
var base_path: String:
	set(value):
		if !value.ends_with("/"):
			value += "/"
		base_path = value
		if base_path_label != null:
			base_path_label.text = "Base path: %s" % [value]

@export var valid_path_color: Color = Color("73F27F")
@export var invalid_path_color: Color = Color("FF786B")
@export var path_responses: Dictionary[StringName, String]

@export var sprite_frames_path: LineEdit
@export var animation_library_path: LineEdit
var _selected_type: StringName

func _ready() -> void :
	get_ok_button().disabled = true
	register_text_enter(path_line_edit)

func close_popup() -> void :
	if visible == false:
		queue_free()

func _text_changed(new_text: String) -> void :
	var _new_text: String = new_text.get_basename()
	if _new_text.is_empty():
		get_ok_button().disabled = true
		path_validator.text = path_responses["empty"]
		path_validator.set("theme_override_colors/font_color", invalid_path_color)
		return

	if ResourceLoader.exists(base_path + _new_text + ".tscn"):
		get_ok_button().disabled = true
		path_validator.text = path_responses["exists"]
		path_validator.set("theme_override_colors/font_color", invalid_path_color)
	else:
		get_ok_button().disabled = false
		path_validator.text = path_responses["valid"]
		path_validator.set("theme_override_colors/font_color", valid_path_color)
