extends Button


@export var action: StringName = &"open_cartridge_bag"

@onready var keybind_label: Label = $KeybindLabel


func _ready() -> void :
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var keycode: Key = event.keycode
			if keycode == 0:
				keycode = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)

			keybind_label.text = "[%s]" % OS.get_keycode_string(keycode)
			break

	if !SaveData.get_flag(&"credits_scroll_seen"):
		hide()


func _input(event: InputEvent) -> void :
	if not is_visible_in_tree():
		return
	if event.is_action_pressed(action):
		_pressed()


func _pressed() -> void :
	SceneChanger.change_to("uid://c56x7ch1lypk3", &"hypno")
