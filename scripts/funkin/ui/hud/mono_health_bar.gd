@tool
class_name MonoHealthBar
extends Control



@onready var bar_animation: AnimationPlayer = $AnimationPlayer

@export_group("References")
@export var eyes_player: AnimationPlayer
@export var health_module: RubiconHealthModule
@export var progress_bar: ProgressBar

var fail_stage: int = 0


func _process(_delta: float) -> void :
	if health_module == null or progress_bar == null:
		return

	var health: float = health_module.health
	var min_health: float = health_module.min_health
	var max_health: float = health_module.max_health

	if max_health == min_health:
		progress_bar.ratio = 0.0
		return

	var health_ratio: float = (health - min_health) / (max_health - min_health)
	progress_bar.ratio = clampf(health_ratio, 0.0, 1.0)


func _on_typing_challenge_challenge_fail(failure: int) -> void :
	fail_stage = failure

	if failure >= 3:
		if health_module:
			health_module.health = 0
		return

	if bar_animation:
		bar_animation.play("first split" if failure == 1 else "second split")

	play_next_eye_fail_stage()


func _on_typing_challenge_force_second_fail() -> void :
	if bar_animation:
		bar_animation.play("second split")
		eyes_player.play("Full")
		eyes_player.seek(0.0, true)

	fail_stage = 2


func play_next_eye_fail_stage() -> void :
	if eyes_player == null:
		return

	var current_anim: = eyes_player.current_animation

	if current_anim == "Left" or current_anim == "LeftLoop":
		eyes_player.play("Right")
		fail_stage = maxi(fail_stage, 2)
		return

	if current_anim == "Right" or current_anim == "RightLoop":
		return

	eyes_player.play("Left")
	fail_stage = maxi(fail_stage, 1)


func force_next_eye_stage() -> void :
	if eyes_player == null:
		return

	var current_anim: = eyes_player.current_animation

	if current_anim == "Left" or current_anim == "LeftLoop":
		eyes_player.play("Right")
		return

	if current_anim == "Right" or current_anim == "RightLoop":
		return

	eyes_player.play("Full")
	fail_stage = fail_stage + 1
