extends CheckBox

@export var property: StringName

func _ready() -> void :
	button_pressed = Settings.get(property)

	if not toggled.is_connected(_on_value_changed):
		toggled.connect(_on_value_changed)

func _on_value_changed(value: bool) -> void :
	Settings.set(property, value)
