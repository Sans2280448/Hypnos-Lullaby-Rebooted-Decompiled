@tool
extends EditorPlugin

const SFKPlugin = preload("res://addons/spriteframes_keyframer/context_menu_plugin.gd")

var _instance: SFKPlugin

func _enter_tree() -> void :
	_instance = SFKPlugin.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _instance)

func _exit_tree() -> void :
	remove_context_menu_plugin(_instance)
