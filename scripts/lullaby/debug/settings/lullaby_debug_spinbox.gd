extends Control

@export var property: StringName
@export var spinbox: SpinBox

func _ready() -> void :
	spinbox.value = Settings.get(property)

	if not spinbox.value_changed.is_connected(_on_value_changed):
		spinbox.value_changed.connect(_on_value_changed)

func _on_value_changed(value: float) -> void :
	Settings.set(property, value)
