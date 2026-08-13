extends CanvasLayer

func _ready() -> void :
	_update_visiblity()

	Settings.applied.connect(_update_visiblity)

func _update_visiblity() -> void :
	visible = Settings.game_autoplay
