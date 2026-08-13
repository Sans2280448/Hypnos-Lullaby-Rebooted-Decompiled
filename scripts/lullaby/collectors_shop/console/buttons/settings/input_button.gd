extends SettingsButton

@export var input: StringName
@export var is_input_game: bool = false
var initial_text: String
var current_input: InputEvent

var detecting_input: bool = false

func _ready() -> void :
	super ()

	if is_input_game:
		current_input = Settings.input_game[input][0]
	else:
		current_input = Settings.input_map[input][0]
	initial_text = text
	text = initial_text + current_input.as_text()

func _input(event: InputEvent) -> void :
	if not self.has_focus():
		return

	if detecting_input and event.is_pressed():
		if is_input_game:
			Settings.input_game[input][0] = event
		else:
			Settings.input_map[input][0] = event
		detecting_input = false
		current_input = event
		Settings.apply_settings()
		text = initial_text + current_input.as_text()
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_CUBIC)
	elif event.is_action_pressed(&"ui_accept"):
		detecting_input = true
		console.play_sound.emit("sfx_soulroom_select_alt")
		text = initial_text + "[...]"
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_CUBIC)
