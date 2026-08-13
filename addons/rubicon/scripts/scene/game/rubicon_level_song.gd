@tool
extends Node
class_name RubiconLevelSong

enum SyncTime{
	STEP, 
	BEAT, 
	MEASURE, 
}

@export var audio_players: Array[AudioStreamPlayer]:
	set(value):
		audio_players = value
		if sync_reference_player == null or !audio_players.has(sync_reference_player):
			if audio_players.is_empty():
				sync_reference_player = null
				return
			sync_reference_player = audio_players[0]
@export var offset: float = 0

@export_group("Syncing", "sync_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var sync_enabled: bool = true

@export var sync_check_every: SyncTime = SyncTime.MEASURE:
	set(value):
		sync_check_every = value
		set_level()

@export var sync_reference_player: AudioStreamPlayer
@export var sync_desync_threshold: float = 0.045

var playing: bool = false

var _level: RubiconLevel:
	set(value):
		_level = value
		set_level()

func _ready() -> void :
	set_process_internal(true)
	connect(&"child_entered_tree", added_player_child)
	connect(&"child_exiting_tree", removed_player_child)

func set_level():
	if _level == null:
		return

	_level.clock.animation_player.connect(&"animation_started", func(_a: StringName): start_playing())
	_level.clock.animation_player.connect(&"animation_finished", func(_a: StringName): stop_playing())

	if !sync_enabled:
		return

	match sync_check_every:
		SyncTime.STEP:
			if _level.clock.beat_change.is_connected(check_for_desync):
				_level.clock.beat_change.disconnect(check_for_desync)

			if _level.clock.measure_change.is_connected(check_for_desync):
				_level.clock.measure_change.disconnect(check_for_desync)

			if !_level.clock.step_change.is_connected(check_for_desync):
				_level.clock.step_change.connect(check_for_desync)

		SyncTime.BEAT:
			if _level.clock.step_change.is_connected(check_for_desync):
				_level.clock.step_change.disconnect(check_for_desync)

			if _level.clock.measure_change.is_connected(check_for_desync):
				_level.clock.measure_change.disconnect(check_for_desync)

			if !_level.clock.beat_change.is_connected(check_for_desync):
				_level.clock.beat_change.connect(check_for_desync)

		SyncTime.MEASURE:
			if _level.clock.step_change.is_connected(check_for_desync):
				_level.clock.step_change.disconnect(check_for_desync)

			if _level.clock.beat_change.is_connected(check_for_desync):
				_level.clock.beat_change.disconnect(check_for_desync)

			if !_level.clock.measure_change.is_connected(check_for_desync):
				_level.clock.measure_change.connect(check_for_desync)

func start_playing() -> void :
	playing = true
	for player: AudioStreamPlayer in audio_players:
		var start_time: float = _level.clock.animation_player.current_animation_position + offset
		if start_time < 0:
			var timer: SceneTreeTimer = get_tree().create_timer(abs(start_time))
			timer.timeout.connect(start_playing)
			return
		player.play(start_time)

func stop_playing() -> void :
	playing = false
	for player: AudioStreamPlayer in audio_players:
		player.stop()

func added_player_child(_node: Node) -> void :
	if !(_node is AudioStreamPlayer) and audio_players.has(_node):
		return

	audio_players.append(_node)

func removed_player_child(_node: Node) -> void :
	if !audio_players.has(_node):
		return

	audio_players.remove_at(audio_players.find(_node))

func check_for_desync() -> void :
	if _level == null or sync_reference_player == null or !sync_enabled:
		return

	var anim_player_time: float = _level.clock.animation_player.current_animation_position + offset
	if abs(sync_reference_player.get_playback_position() - anim_player_time) > sync_desync_threshold:

		for player: AudioStreamPlayer in audio_players:
			if player.playing:
				player.seek(anim_player_time)

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_INTERNAL_PROCESS:
			if _level != null and ( !_level.clock.animation_player.is_playing() and playing):
				stop_playing()

		NOTIFICATION_PARENTED:
			if _level != null:
				_level = null

			var parent: Node = get_parent()
			while parent != null:
				if parent is RubiconLevel:
					_level = parent
					break

				parent = parent.get_parent()
