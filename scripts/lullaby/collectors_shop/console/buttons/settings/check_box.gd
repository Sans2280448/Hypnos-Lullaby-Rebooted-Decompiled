extends Node2D

@export var toggle_button: SettingsButton

var check: AnimatedSprite2D
var check_anim: AnimationPlayer

func _ready() -> void :
	if toggle_button:
		toggle_button.toggle_checkbox.connect(_toggle_checkbox)

	check = find_child("Check")
	check_anim = check.get_child(0)

func _toggle_checkbox():
	check_anim.stop()
	if get_parent().is_activated:
		check_anim.play("activate")
	else:
		check_anim.play("deactivate")
