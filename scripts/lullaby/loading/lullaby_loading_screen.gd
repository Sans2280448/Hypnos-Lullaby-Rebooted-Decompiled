class_name LullabyLoadingScreen extends Node

@export var animation_start: StringName
@export var animation_end: StringName
@export var animation_player: AnimationPlayer

signal progress_updated(value: float)

func start() -> void :
	animation_player.play(animation_start)
	animation_player.seek(0.0)

	await animation_player.animation_finished

func update_progress(value: float) -> void :
	progress_updated.emit(value)

func complete() -> void :
	animation_player.play(animation_end)
	animation_player.seek(0.0)

	await animation_player.animation_finished
