class_name ShopBindUi extends Label

@export_multiline() var format_text: String = "":
	get:
		return _text
	set(val):
		if _text == val:
			return

		_text = val
		_update_text(current_bind_type)

var current_bind_type: BindType = BindType.KBM

var _text: String = ""

enum BindType
{
	KBM, 
	CONTROLLER
}

func _ready() -> void :
	_update_text(current_bind_type)
	Settings.applied.connect(_on_settings_applied)

func _input(event: InputEvent) -> void :
	var bind_type: BindType = BindType.KBM
	if event is InputEventKey or InputEventMouseButton or InputEventMouseMotion:
		bind_type = BindType.KBM

	if event is InputEventJoypadButton or InputEventJoypadMotion:
		bind_type = BindType.CONTROLLER

	if bind_type != current_bind_type:
		_update_text(bind_type)

	current_bind_type = bind_type

func _on_settings_applied() -> void :
	_update_text(current_bind_type)

func _update_text(bind_type: BindType) -> void :
	var current_text: String = format_text

	var split_text: PackedStringArray = current_text.split("$")
	var inputs: Array[StringName] = []
	for single_text: String in split_text:
		if _has_input(single_text) and not inputs.has(single_text):
			inputs.append(single_text)

	for input: StringName in inputs:
		current_text = current_text.replace("$" + input + "$", _get_input_or_default(input, bind_type).as_text())

	text = current_text.replace(" - Physical", "")

func _has_input(action_name: StringName) -> bool:
	return InputMap.has_action(action_name) or Settings.input_game.has(action_name)

func _get_input_or_default(action_name: StringName, bind_type: BindType) -> InputEvent:
	if InputMap.has_action(action_name):
		var events: Array[InputEvent] = InputMap.action_get_events(action_name)
		var index: int = events.find_custom(_input_is_of_type.bind(bind_type))
		if index != -1:
			return events[index]

		return events[0]

	var events: Array[InputEvent] = Settings.input_game[action_name]
	var index: int = events.find_custom(_input_is_of_type.bind(bind_type))
	if index != -1:
		return events[index]

	return events[0]

func _input_is_of_type(input: InputEvent, bind_type: BindType) -> bool:
	match bind_type:
		BindType.KBM:
			return input is InputEventKey or InputEventMouseButton or InputEventMouseMotion
		BindType.CONTROLLER:
			return input is InputEventJoypadButton or InputEventJoypadMotion

	return false
