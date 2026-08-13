@tool
class_name RubiChartScrollVelocity extends Resource

@export var measure_time: float
@export_range(0, 100, 0.001, "or_greater") var multiplier: float = 1

var millisecond_time: float
var position: float

func initialize(time_changes: Array[RubiconTimeChange]) -> void :
	millisecond_time = RubiconTimeChange.get_millisecond_at_measure(time_changes, measure_time)
	position = millisecond_time

func initialize_with_previous(time_changes: Array[RubiconTimeChange], last_velocity: RubiChartScrollVelocity) -> void :
	initialize(time_changes)
	position = last_velocity.position + ((millisecond_time - last_velocity.millisecond_time) * last_velocity.multiplier)

static func get_graphic_position_at_millisecond(velocities: Array[RubiChartScrollVelocity], millisecond_time: float) -> float:
	var vel_index: int = velocities.size() - 1
	for i in velocities.size():
		if velocities[i].millisecond_time > millisecond_time:
			vel_index = i - 1
			break

	var velocity: RubiChartScrollVelocity = velocities[vel_index]
	return velocity.position + ((millisecond_time - velocity.millisecond_time) * velocity.multiplier)
