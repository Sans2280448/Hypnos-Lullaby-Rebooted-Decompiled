extends Control


@export var anim_player: AnimationPlayer
@export var sound_player: AudioStreamPlayer


func _on_gameover_finished() -> void :
	get_tree().change_scene_to_file("uid://k26b7med2dat")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void :
	_on_gameover_finished()


func _on_timer_timeout() -> void :
	if anim_player:
		anim_player.play(&"animation")
	elif sound_player:
		sound_player.play()
