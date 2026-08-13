extends Node


@export var animation_player: AnimationPlayer


func _on_animation_finished(anim_name: StringName) -> void :
	var play_angel: = not SaveData.get_flag(&"credits_scroll_seen")
	match anim_name:
		&"scene":
			if play_angel:
				animation_player.play(&"angel")
				animation_player.seek(0.0, true)
				return

			SceneChanger.change_to("uid://bqkjiwokrcvo", &"hypno", true)

		&"angel":
			SaveData.set_flag(&"credits_scroll_seen", true)
			SaveData.save()
			SceneChanger.change_to("uid://bqkjiwokrcvo", &"hypno", true)


func _input(event: InputEvent) -> void :
	if event.is_action(&"ui_accept") and SaveData.get_flag(&"credits_scroll_seen"):
		SceneChanger.change_to("uid://bqkjiwokrcvo", &"hypno", true)
