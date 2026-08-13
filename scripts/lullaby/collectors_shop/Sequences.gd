@tool
class_name ShopSequences
extends Node

@export_group("Voiceline Sync")
@export var voicelines: Dictionary[String, AudioStream] = {}
@export var voiceline_offset: float = 0.0
@export var voiceline_desync_threshold: float = 0.045

var animation_player: AnimationPlayer:
	get:
		return _animation_player
var _animation_player: AnimationPlayer

var voiceline: AudioStreamPlayer3D:
	get:
		return _voiceline
var _voiceline: AudioStreamPlayer3D

func _ready() -> void :
	update_children()
	update_configuration_warnings()

func _process(_delta: float) -> void :
	sync_players()
	sync_voiceline()

func _notification(what: int) -> void :
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		update_children()
		update_configuration_warnings()

func update_children() -> void :
	_animation_player = get_child(0) as AnimationPlayer if get_child_count() > 0 else null
	_voiceline = get_child(1) as AudioStreamPlayer3D if get_child_count() > 1 else null

func sync_players() -> void :
	if animation_player == null:
		update_children()
		return

	var anim: = animation_player.current_animation
	if anim == "":
		return

func sync_voiceline() -> void :
	if animation_player == null or voiceline == null:
		return

	if not animation_player.is_playing():
		return

	var anim: = animation_player.current_animation

	if anim == "":
		voiceline.stop()
		return

	if not voicelines.has(anim):
		return

	var stream: = voicelines[anim]

	if voiceline.stream != stream:
		voiceline.stop()
		voiceline.stream = stream

	var target_time: = animation_player.current_animation_position + voiceline_offset

	if target_time < 0.0:
		voiceline.stop()
		return

	var stream_length: = stream.get_length()

	if stream_length > 0.0 and target_time >= stream_length:
		voiceline.stop()
		return

	voiceline.stream_paused = false

	if not voiceline.playing:
		voiceline.play(target_time)
		return

	if abs(voiceline.get_playback_position() - target_time) > voiceline_desync_threshold:
		voiceline.seek(target_time)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if animation_player == null:
		warnings.append("ShopSequences requires its first child to be an AnimationPlayer.")

	if voiceline == null:
		warnings.append("ShopSequences expects its second child to be an AudioStreamPlayer3D.")

	return warnings
