@tool
class_name LullabyLevelSong
extends RubiconLevelSong


var start_timer: Timer


func added_player_child(node: Node) -> void :
	if node is not AudioStreamPlayer or audio_players.has(node):
		return

	audio_players.append(node)


func removed_player_child(node: Node) -> void :
	if node is not AudioStreamPlayer or not audio_players.has(node):
		return

	audio_players.erase(node)


func start_playing() -> void :
	playing = true
	for player: AudioStreamPlayer in audio_players:
		var start_time: float = _level.clock.animation_player.current_animation_position + offset
		if start_time < 0:
			if not is_instance_valid(start_timer):
				start_timer = Timer.new()
				start_timer.wait_time = abs(start_time)
				start_timer.one_shot = true
				add_child(start_timer)

				start_timer.start()
				start_timer.timeout.connect(start_playing)
			return
		player.play(start_time)
