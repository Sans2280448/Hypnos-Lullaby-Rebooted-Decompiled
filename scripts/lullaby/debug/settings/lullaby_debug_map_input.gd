extends Control

@export var map_input: StringName = &"funkin_pause"
@export var button: Button

var _in_binding_mode: bool = false

func _ready() -> void :
	var event: InputEvent = get_game_input_event()
	button.text = event.as_text()

	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void :
	button.text = "..."
	get_viewport().set_input_as_handled()

	focus_mode = Control.FOCUS_NONE
	release_focus()

	_in_binding_mode = true

func _input(event: InputEvent) -> void :
	if event is InputEventMouseMotion or event.is_released():
		return

	if not _in_binding_mode:
		return

	get_viewport().set_input_as_handled()

	_in_binding_mode = false
	button.text = event.as_text()
	set_game_input_event(event)

func get_game_input_event() -> InputEvent:
	return Settings.input_map[map_input][0]

func set_game_input_event(event: InputEvent) -> void :
	Settings.input_map[map_input][0] = event
