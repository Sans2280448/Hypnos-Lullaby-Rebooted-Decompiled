extends AnimatedSprite2D

@export var console: Control
@export var portrait: AnimatedSprite2D
@export var settings_container: TabContainer


func _process(_delta: float) -> void :
	if console.in_submenu:
		portrait.visible = false
		settings_container.visible = true
	else:
		portrait.visible = true
		settings_container.visible = false
