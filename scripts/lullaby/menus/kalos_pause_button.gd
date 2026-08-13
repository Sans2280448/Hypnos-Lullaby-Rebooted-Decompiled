class_name KalosPauseButton extends Button

@export var hoverer: AnimationPlayer
@export var hover_animation: StringName
@export var unhover_animation: StringName
@export var hover_audio: AudioStreamPlayer
@export var animation_player: AnimationPlayer
@export var animation_pressed: StringName

signal requested_action

func _ready() -> void :
	focus_entered.connect(_on_hover)
	focus_exited.connect(_on_unhover)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)

	animation_player.animation_finished.connect(_on_animation_finished)

func _on_hover() -> void :
	hoverer.play(hover_animation)
	hover_audio.play()

func _on_unhover() -> void :
	hoverer.play(unhover_animation)

func _on_animation_finished(anim: StringName) -> void :
	if anim == animation_pressed:
		requested_action.emit()
		animation_player.play(&"RESET", -1, 1.0, false)
