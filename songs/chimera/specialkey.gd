extends RichTextLabel

func _ready() -> void :
	if Settings.game_autoplay:
		visible = false

	text = "[shake rate=10.0 level=7]Catch the pulse with your heart\n[%s] to calm yourself." % _get_input_name()

func photographbitch() -> void :
	text = "[shake rate=10.0 level=7]Press [" + _get_input_name() + "] to photograph"

func _get_input_name() -> String:
	if Settings.game_autoplay:
		return "◉"

	return Settings.get_input_name(&"lullaby_special")
