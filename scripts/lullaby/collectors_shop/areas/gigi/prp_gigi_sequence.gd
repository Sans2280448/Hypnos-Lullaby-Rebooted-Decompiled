class_name ShopGigiAudioSequence extends Resource

@export var sequence: Array[AudioStream]

var _current_id: int = 0

func reset() -> void :
	_current_id = 0

func get_next() -> AudioStream:
	var audio: AudioStream = sequence[_current_id]
	_current_id += 1
	return audio

func is_finished() -> bool:
	return _current_id >= sequence.size()
