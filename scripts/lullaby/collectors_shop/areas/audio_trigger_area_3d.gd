extends TriggerArea3D

@export var audio: AudioStreamPlayer3D

func trigger() -> void :
	audio.play()
