extends Node

@export var time_activate: float = 0.0
@export var clock: RubiconLevelClock

var _activated: bool = false

func _process(_delta: float) -> void :
	var passed_second_phase: bool = SaveData.get_flag(&"chimera_2nd_phase_first")
	if passed_second_phase:
		return

	if not _activated and clock.time_milliseconds < time_activate:
		return

	_activated = true
	SaveData.set_flag(&"chimera_2nd_phase_first", true)
	SaveData.save()
