extends FocusArea3D


@export var song_name: StringName = &"chimera"
@export var board_area: FocusArea3D

func _ready() -> void :
	can_interact = SaveData.has_passed_song(song_name)


func _input(event: InputEvent) -> void :
	if event.is_echo() or not event.is_pressed():
		return

	if event.is_action(&"ui_cancel") and is_focused and board_area:
		get_viewport().set_input_as_handled()
		board_area.can_interact = true
		board_area.register_trigger()
		sequences.animation_player.play(&"sequence_board")
