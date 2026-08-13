@tool
extends Control

@export var selector: Control

@export_group("Node Icon")
@export var editor_node_icon_name: StringName:
	set(value):
		editor_node_icon_name = value
		set_node_icon()
@export var node_icon: TextureRect:
	set(value):
		node_icon = value
		set_node_icon()

@export_group("Checkbox Icon")
@export var unchecked_editor_checkbox_icon_name: StringName:
	set(value):
		unchecked_editor_checkbox_icon_name = value
		set_checkbox_icon(_selected)
@export var checked_editor_checkbox_icon_name: StringName:
	set(value):
		checked_editor_checkbox_icon_name = value
		set_checkbox_icon(_selected)
@export var checkbox_icon: TextureRect:
	set(value):
		checkbox_icon = value
		set_checkbox_icon(_selected)

var _mouse_in: bool = false
var _selected: bool = false:
	set(value):
		_selected = value
		set_checkbox_icon(value)

func _ready() -> void :
	if Engine.is_editor_hint():
		if selector == null:
			return

		selector.item_selections.append(get_path())
		if name.to_lower() == &"node2d":
			selector.set_item(get_path(), true)
		connect("mouse_entered", _on_mouse_entered)
		connect("mouse_exited", _on_mouse_exited)

func set_node_icon() -> void :
	if !Engine.is_editor_hint():
		return

	if node_icon != null and EditorInterface.get_base_control().has_theme_icon(editor_node_icon_name, &"EditorIcons"):
		node_icon.texture = EditorInterface.get_base_control().get_theme_icon(editor_node_icon_name, &"EditorIcons")

func set_checkbox_icon(selected: bool) -> void :
	if !Engine.is_editor_hint():
		return

	if checkbox_icon != null:
		if !selected and EditorInterface.get_base_control().has_theme_icon(unchecked_editor_checkbox_icon_name, &"EditorIcons"):
			checkbox_icon.texture = EditorInterface.get_base_control().get_theme_icon(unchecked_editor_checkbox_icon_name, &"EditorIcons")
		if selected and EditorInterface.get_base_control().has_theme_icon(checked_editor_checkbox_icon_name, &"EditorIcons"):
			checkbox_icon.texture = EditorInterface.get_base_control().get_theme_icon(checked_editor_checkbox_icon_name, &"EditorIcons")

func _on_mouse_entered() -> void :
	if !Engine.is_editor_hint():
		return

	_mouse_in = true

func _on_mouse_exited() -> void :
	if !Engine.is_editor_hint():
		return

	_mouse_in = false
	modulate = Color.WHITE

func _input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_released() and _mouse_in:
			if !_selected:
				selector.set_item(get_path(), true)
			modulate = Color.WHITE
		if event.is_pressed() and _mouse_in:
			modulate = Color.LIGHT_GRAY

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			if node_icon != null:
				node_icon.texture = null
			if checkbox_icon != null:
				checkbox_icon.texture = null
