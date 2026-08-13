extends Control

@export var option_button: OptionButton
@export var window_resolution: Control

func _ready() -> void :
	option_button.selected = int(Settings.display_window_mode)

	if not option_button.item_selected.is_connected(_on_item_selected):
		option_button.item_selected.connect(_on_item_selected)

	_update_resolution_visibility()

func _on_item_selected(idx: int) -> void :
	Settings.display_window_mode = idx as Window.Mode

	if not window_resolution:
		return

	_update_resolution_visibility()

func _update_resolution_visibility() -> void :
	window_resolution.visible = Settings.display_window_mode != Window.Mode.MODE_FULLSCREEN
