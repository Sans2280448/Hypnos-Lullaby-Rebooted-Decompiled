extends Node3D

func _ready() -> void :
	visible = Settings.get(&"game_flashing_lights")
