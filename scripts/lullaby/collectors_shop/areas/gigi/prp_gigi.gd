extends TriggerArea3D

@export var sequence_id: int = 0
@export var sequences: Array[ShopGigiAudioSequence]
@export var player: AudioStreamPlayer3D

var _can_play: bool = true

var _has_seen: Array[int] = []
var _repeat_counter: int = 0

func trigger() -> void :
	if not _can_play:
		return

	_can_play = false

	var cur_sequence: ShopGigiAudioSequence = sequences[sequence_id]
	player.stream = sequences[sequence_id].get_next()

	if cur_sequence.is_finished():
		cur_sequence.reset()

		sequence_id = randi_range(0, sequences.size() - 1)
		if _repeat_counter > 3:
			if _has_seen.size() < sequences.size():
				while _has_seen.has(sequence_id):
					sequence_id = randi_range(0, sequences.size() - 1)

			if not _has_seen.has(sequence_id):
				_has_seen.append(sequence_id)

			_repeat_counter = 0
		else:
			_repeat_counter += 1

	player.play()
	await player.finished

	_can_play = true
