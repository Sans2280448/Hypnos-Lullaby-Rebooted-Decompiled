extends TriggerArea3D


@export var target: Node3D
@export var animation_player: AnimationPlayer
@export var animation_name: StringName
@export var allow_animation_name: StringName
@export var poke_sound_player: AudioStreamPlayer3D
@export var restart_animation_when_poked: bool = true
@export var queued_animation_name: StringName


func _process(_delta: float) -> void :
	if target != null:
		can_interact = target.visible


func trigger() -> void :
	if not can_interact:
		return

	if !allow_animation_name.is_empty() and animation_player.current_animation != allow_animation_name:
		return

	animation_player.play(animation_name, 0.25)
	poke_sound_player.play()

	if restart_animation_when_poked:
		animation_player.seek(0.0)

	if not queued_animation_name.is_empty():
		animation_player.queue(queued_animation_name)
