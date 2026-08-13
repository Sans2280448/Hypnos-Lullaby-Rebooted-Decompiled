extends Node2D
class_name MonochromeGameover

static var skip_first_part: bool = true;

@export var animation_player: AnimationPlayer;
@export var boyfriend_scene: Node2D;


@export var baby_mode_speaker: AudioStreamPlayer
@export var baby_mode_lines: Array[AudioStream]

func _ready() -> void :
	if skip_first_part:
		animation_player.play(&"over_loop")
	else:
		animation_player.play(&"over_start")

func _on_animation_changed(_old: StringName, new: StringName) -> void :
	if new == &"over_loop" and Settings.lullaby_baby_mode and baby_mode_speaker:
		baby_mode_speaker.stream = baby_mode_lines.pick_random()
		baby_mode_speaker.play()

func _input(event: InputEvent) -> void :
	if not boyfriend_scene.visible or event.is_echo() or not event.is_pressed():
		return
	if event.is_action(&"ui_accept"):
		animation_player.play(&"over_confirm")
		await animation_player.animation_finished

		SceneChanger.change_to(&"uid://dfflo57l50r1f", &"hypno")
