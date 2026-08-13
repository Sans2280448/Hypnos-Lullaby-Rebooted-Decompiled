@tool
class_name RubiconTimeChange extends Resource

@export var measure: float = 0.0
@export var bpm: float = 100.0
@export var time_signature_numerator: float = 4.0
@export var time_signature_denominator: float = 4.0

@export var millisecond_time: float = 0.0

func _validate_property(property: Dictionary) -> void :
	if property.name == "millisecond_time":
		property.usage = PROPERTY_USAGE_EDITOR + PROPERTY_USAGE_READ_ONLY

static func update(time_changes: Array[RubiconTimeChange]) -> void :
	for i in range(1, time_changes.size()):
		time_changes[i].millisecond_time = time_changes[i - 1].millisecond_time + RubiconLevelClock.measure_to_millisecond(time_changes[i].measure - time_changes[i - 1].measure, time_changes[i - 1].bpm, time_changes[i - 1].time_signature_numerator)

static func get_time_change_at_millisecond(time_changes: Array[RubiconTimeChange], millisecond: float) -> RubiconTimeChange:
	return get_time_change_at_measure(time_changes, get_measure_at_millisecond(time_changes, millisecond))

static func get_time_change_at_measure(time_changes: Array[RubiconTimeChange], measure: float) -> RubiconTimeChange:
	if time_changes.size() == 1 or measure < 0:
		return time_changes[0]

	for t in range(1, time_changes.size()):
		if time_changes[t].measure < measure:
			continue

		return time_changes[t - 1]

	return time_changes[time_changes.size() - 1]

static func get_time_change_at_beat(time_changes: Array[RubiconTimeChange], beat: float) -> RubiconTimeChange:
	return get_time_change_at_measure(time_changes, get_measure_at_beat(time_changes, beat))

static func get_time_change_at_step(time_changes: Array[RubiconTimeChange], step: float) -> RubiconTimeChange:
	return get_time_change_at_measure(time_changes, get_measure_at_step(time_changes, step))

static func get_millisecond_at_measure(time_changes: Array[RubiconTimeChange], measure: float) -> float:
	if time_changes.size() == 1 or measure < 0:
		return RubiconLevelClock.measure_to_millisecond(measure, time_changes[0].bpm, time_changes[0].time_signature_numerator)

	for i in range(1, time_changes.size()):
		var current: RubiconTimeChange = time_changes[i]
		if measure > current.measure:
			continue

		var previous: RubiconTimeChange = time_changes[i - 1]
		return previous.millisecond_time + RubiconLevelClock.measure_to_millisecond(measure - previous.measure, previous.bpm, previous.time_signature_numerator)

	var last_time_change: RubiconTimeChange = time_changes.back()
	return last_time_change.millisecond_time + RubiconLevelClock.measure_to_millisecond(measure - last_time_change.measure, last_time_change.bpm, last_time_change.time_signature_numerator)

static func get_millisecond_at_beat(time_changes: Array[RubiconTimeChange], beat: float) -> float:
	return get_millisecond_at_measure(time_changes, get_measure_at_beat(time_changes, beat))

static func get_millisecond_at_step(time_changes: Array[RubiconTimeChange], step: float) -> float:
	return get_millisecond_at_measure(time_changes, get_measure_at_step(time_changes, step))

static func get_measure_at_millisecond(time_changes: Array[RubiconTimeChange], millisecond: float) -> float:
	for i: int in time_changes.size():
		var current: RubiconTimeChange = time_changes[i]
		var is_negative: bool = millisecond < 0

		if not is_negative:
			if millisecond < current.millisecond_time:
				continue

			if i < time_changes.size() - 1 and millisecond >= time_changes[i + 1].millisecond_time:
				continue

		return current.measure + ((millisecond - current.millisecond_time) / RubiconLevelClock.measure_to_millisecond(1, current.bpm, current.time_signature_numerator))

	return 0

static func get_measure_at_beat(time_changes: Array[RubiconTimeChange], beat: float) -> float:
	if time_changes.size() == 1 or beat < 0:
		return RubiconLevelClock.beats_to_measures(beat, time_changes[0].time_signature_numerator)

	var beat_count: float = 0
	for i in range(1, time_changes.size()):
		var current: RubiconTimeChange = time_changes[i]
		var previous: RubiconTimeChange = time_changes[i - 1]

		var beat_length: float = RubiconLevelClock.measure_to_beats(current.measure - previous.measure, previous.time_signature_numerator)
		if beat_count + beat_length > beat:
			return previous.measure + RubiconLevelClock.beats_to_measures(beat - beat_count, previous.time_signature_numerator)

		beat_count += beat_length

	return 0.0

static func get_measure_at_step(time_changes: Array[RubiconTimeChange], step: float) -> float:
	if time_changes.size() == 1 or step < 0:
		return RubiconLevelClock.steps_to_measures(step, time_changes[0].time_signature_numerator, time_changes[0].time_signature_denominator)

	var step_count: float = 0
	for i in range(1, time_changes.size()):
		var current: RubiconTimeChange = time_changes[i]
		var previous: RubiconTimeChange = time_changes[i - 1]

		var step_length: float = RubiconLevelClock.measure_to_beats(current.measure - previous.measure, previous.time_signature_numerator)
		if step_count + step_length > step:
			return previous.measure + RubiconLevelClock.steps_to_measures(step - step_count, previous.time_signature_numerator, previous.time_signature_denominator)

		step_count += step_length

	return 0.0

static func get_beat_at_millisecond(time_changes: Array[RubiconTimeChange], millisecond: float) -> float:
	return get_beat_at_measure(time_changes, get_measure_at_millisecond(time_changes, millisecond))

static func get_beat_at_measure(time_changes: Array[RubiconTimeChange], measure: float) -> float:
	if time_changes.size() == 1 or measure < 0:
		return RubiconLevelClock.measure_to_beats(measure, time_changes[0].time_signature_numerator)

	var beat_count: float = 0; var measure_count: float = 0
	for i in range(1, time_changes.size()):
		var current: RubiconTimeChange = time_changes[i]
		var previous: RubiconTimeChange = time_changes[i - 1]

		var measure_length: float = current.measure - previous.measure
		var beat_length: float = RubiconLevelClock.measure_to_beats(measure_length, previous.time_signature_numerator)
		if measure_count + measure_length > measure:
			return beat_count + RubiconLevelClock.measure_to_beats(measure - previous.measure, previous.time_signature_numerator)

		beat_count += beat_length
		measure_count += measure_length

	var last: RubiconTimeChange = time_changes[time_changes.size() - 1]
	return beat_count + RubiconLevelClock.measure_to_beats(measure - last.measure, last.time_signature_numerator)

static func get_beat_at_step(time_changes: Array[RubiconTimeChange], step: float) -> float:
	return get_beat_at_measure(time_changes, get_measure_at_step(time_changes, step))

static func get_step_at_millisecond(time_changes: Array[RubiconTimeChange], millisecond: float) -> float:
	return get_step_at_measure(time_changes, get_measure_at_millisecond(time_changes, millisecond))

static func get_step_at_measure(time_changes: Array[RubiconTimeChange], measure: float) -> float:
	if time_changes.size() == 1 or measure < 0:
		return RubiconLevelClock.measure_to_steps(measure, time_changes[0].time_signature_numerator, time_changes[0].time_signature_denominator)

	var step_count: float = 0; var measure_count: float = 0
	for i in range(1, time_changes.size()):
		var current: RubiconTimeChange = time_changes[i]
		var previous: RubiconTimeChange = time_changes[i - 1]

		var measure_length: float = current.measure - previous.measure
		var step_length: float = RubiconLevelClock.measure_to_steps(current.measure - previous.measure, previous.time_signature_numerator, previous.time_signature_denominator)
		if measure_count + measure_length > measure:
			return step_count + RubiconLevelClock.measure_to_steps(measure - previous.measure, previous.time_signature_numerator, previous.time_signature_denominator)

		step_count += step_length
		measure_count += measure_length

	var last: RubiconTimeChange = time_changes[time_changes.size() - 1]
	return step_count + RubiconLevelClock.measure_to_steps(measure - last.measure, last.time_signature_numerator, last.time_signature_denominator)

static func get_step_at_beat(time_changes: Array[RubiconTimeChange], beat: float) -> float:
	return get_step_at_measure(time_changes, get_measure_at_beat(time_changes, beat))
