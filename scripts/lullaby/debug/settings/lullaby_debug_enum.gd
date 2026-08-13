extends Control

@export var property: StringName
@export var option_button: OptionButton

func _ready() -> void :
	option_button.selected = int(Settings.get(property))

	if not option_button.item_selected.is_connected(_on_item_selected):
		option_button.item_selected.connect(_on_item_selected)

func _on_item_selected(idx: int) -> void :
	Settings.set(property, idx)
