extends CanvasItem

func _ready() -> void :
	visible = Settings.get(&"game_flashing_lights")
