@tool
class_name RubiconLevelNoteInputMap extends Resource

@export var inputs: Dictionary[InputEvent, StringName]

func has_event_registered(event: InputEvent) -> bool:
	for input in inputs:
		if input.is_match(event):
			return true

	return false

func get_handler_id_for_event(event: InputEvent) -> StringName:
	for input in inputs:
		if input.is_match(event):
			return inputs[input]

	return &""
