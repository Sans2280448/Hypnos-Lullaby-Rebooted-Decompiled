class_name ConsoleTab
extends Control

@export var tab_container: TabContainer
@export var default_focus: Control
var _last_focus: Control

func save_last_focus() -> void :
	_last_focus = get_viewport().gui_get_focus_owner()
