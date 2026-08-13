@tool
extends PopupMenu

const ConverterWindow = preload("res://addons/rubichart_converter/converter_window.gd")
const FunkinConverter = preload("res://addons/rubichart_converter/converters/funkin.gd")
const FantasyConverter = preload("res://addons/rubichart_converter/converters/fantasy.gd")

@export_group("References", "reference_")
@export var reference_window_scene: PackedScene

var _window: ConverterWindow

func _enter_tree() -> void :
	_window = reference_window_scene.instantiate()
	_window.visible = false
	add_child(_window)

func _exit_tree() -> void :
	remove_child(_window)
	_window.queue_free()

func on_clicked(index: int) -> void :
	match index:
		0:
			FunkinConverter.convert_chart([EditorInterface.get_selected_paths()[0]])
		1:
			FantasyConverter.convert_chart([EditorInterface.get_selected_paths()[0]])
