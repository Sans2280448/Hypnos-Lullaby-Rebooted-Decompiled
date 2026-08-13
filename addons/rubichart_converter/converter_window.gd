@tool
extends Window

@export_group("References", "reference_")
@export var reference_key_list: ItemList
@export var reference_bool_value_container: Control
@export var reference_bool_value_checkbox: CheckBox
@export var reference_string_value_container: Control
@export var reference_string_value_edit: LineEdit
@export var reference_confirm_button: Button

var _dict: Dictionary[String, Variant]
var _key_dict: Dictionary[int, String]
var _cur_key: String

var _was_closed_prematurely: bool = false

func reset() -> void :
	reference_key_list.clear()
	_was_closed_prematurely = false

func switch_to_property(index: int) -> void :
	_cur_key = _key_dict[index]

	match typeof(_dict[_cur_key]):
		TYPE_BOOL:
			reference_bool_value_container.visible = true
			reference_string_value_container.visible = false
		TYPE_STRING:
			reference_bool_value_container.visible = false
			reference_string_value_container.visible = true

func bool_value_submitted(new_value: bool) -> void :
	_dict[_cur_key] = reference_bool_value_checkbox.button_pressed

func string_value_submitted(new_text: String) -> void :
	_dict[_cur_key] = new_text

func fill_dictionary_values(dictionary: Dictionary[String, Variant]) -> bool:
	var proceed: bool = false
	for value in dictionary.values():
		if value == null:
			proceed = true

	if not proceed:
		return true

	_dict = dictionary

	visible = true
	reset()

	var index: int = 0
	for key in dictionary.keys():
		_key_dict[index] = key
		reference_key_list.add_item(key)
		index += 1

	switch_to_property(0)

	await reference_confirm_button.pressed
	visible = false

	if _was_closed_prematurely:
		return false

	return true

func close_requested() -> void :
	_was_closed_prematurely = true
	reference_confirm_button.pressed.emit()
