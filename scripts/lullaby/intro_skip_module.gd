class_name LullabyIntroSkipModule
extends Node


@export var start_player: AnimationPlayer
@export var skips: Dictionary[Node, float] = {}


func _ready() -> void :
	if not LullabyGameoverModule.has_died or skips.is_empty():
		return

	if is_instance_valid(start_player):
		start_player.play(&"start")

	await RenderingServer.frame_pre_draw

	for player in skips:
		player.play()

		if player is AnimationPlayer:
			player.seek(skips[player], true)
		else:
			player.seek(skips[player])
