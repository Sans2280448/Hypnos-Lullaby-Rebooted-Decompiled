@tool
extends EditorPlugin

const ConverterPopup: PackedScene = preload("res://addons/rubichart_converter/converter_popup.tscn")
const ConverterContextMenu: GDScript = preload("res://addons/rubichart_converter/context_menu_plugin.gd")

var _converter_popup_instance: PopupMenu
var _converter_context_menu_instance: EditorContextMenuPlugin

func _enter_tree() -> void :

	_converter_popup_instance = ConverterPopup.instantiate()
	add_tool_submenu_item("Convert to RubiChart", _converter_popup_instance)

	_converter_context_menu_instance = ConverterContextMenu.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _converter_context_menu_instance)

func _exit_tree() -> void :
	if _converter_popup_instance == null or _converter_context_menu_instance == null:
		return

	remove_tool_menu_item("Convert to RubiChart")
	remove_context_menu_plugin(_converter_context_menu_instance)
