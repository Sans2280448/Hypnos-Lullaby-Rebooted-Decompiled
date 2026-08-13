extends RichTextLabel


var last_text: String


func _ready() -> void :
	last_text = text
	update_text_format()


func _process(_delta: float) -> void :
	if text != last_text:
		last_text = text
		update_text_format()


func update_text_format() -> void :
	for event: InputEvent in InputMap.action_get_events(&"lullaby_special"):
		if event is InputEventKey:
			var keycode: Key = event.keycode
			if keycode == 0:
				keycode = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)

			text = text.replace("$SPECIAL", "[ %s ]" % OS.get_keycode_string(keycode))
			break
