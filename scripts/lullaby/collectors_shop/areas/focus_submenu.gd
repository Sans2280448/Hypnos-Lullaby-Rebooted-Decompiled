class_name SubmenuArea extends FocusArea3D

@export var submenu_viewport: SubViewport
@export var open_sound: AudioStreamPlayer

func trigger() -> void :
	if not can_interact:
		return

	sequences.animation_player.play(animation_name)

	if open_sound:
		open_sound.play()

func _input(event: InputEvent) -> void :
	if submenu_viewport != null and is_focused and event is InputEventKey:
		submenu_viewport.push_input(event)
