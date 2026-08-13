extends Control

@export var width: SpinBox
@export var height: SpinBox

var _connected: bool = false

func _ready() -> void :
	width.value = Settings.display_resolution.x
	height.value = Settings.display_resolution.y

	if not _connected:
		width.value_changed.connect(_on_width_changed)
		height.value_changed.connect(_on_height_changed)

		_connected = true

func _on_width_changed(value: float) -> void :
	Settings.display_resolution.x = int(value)

func _on_height_changed(value: float) -> void :
	Settings.display_resolution.y = int(value)
