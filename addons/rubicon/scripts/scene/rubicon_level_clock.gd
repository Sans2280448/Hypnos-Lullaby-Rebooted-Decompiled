@tool
class_name RubiconLevelClock extends Node

@export var offset: float = 0.0

@export_group("Time", "time_")
@export var time_milliseconds: float:
	get:
		var is_on_animation: bool = animation_player != null and (animation_player.is_animation_active() or animation_player.is_playing())
		if not is_on_animation:
			return 0

		return (_animation_player.current_animation_position + offset) * 1000.0
	set(val):
		var is_on_animation: bool = animation_player != null and (animation_player.is_animation_active() or animation_player.is_playing())
		if not is_on_animation:
			return

		_animation_player.seek((val / 1000.0) - offset)
		recalculate_cache()

@export var time_measure: float:
	get:
		return _cached_measure
	set(val):
		time_milliseconds = RubiconTimeChange.get_millisecond_at_measure(get_time_changes(), val)

@export var time_beat: float:
	get:
		return _cached_beat
	set(val):
		time_milliseconds = RubiconTimeChange.get_millisecond_at_beat(get_time_changes(), val)

@export var time_step: float:
	get:
		return _cached_step
	set(val):
		time_milliseconds = RubiconTimeChange.get_millisecond_at_step(get_time_changes(), val)

var level: RubiconLevel:
	get:
		return _level

var animation_player: AnimationPlayer:
	get:
		return _animation_player

var _level: RubiconLevel
var _animation_player: AnimationPlayer

var _current_frame_time: float
var _relative_time_offset: float

var _last_measure: int = -1
var _last_beat: int = -1
var _last_step: int = -1
var _last_time_change: RubiconTimeChange

var _cached_measure: float
var _cached_beat: float
var _cached_step: float

signal measure_change
signal beat_change
signal step_change
signal time_change_set

func get_time_precise() -> float:
	return _current_frame_time + (Time.get_unix_time_from_system() - _relative_time_offset) * 1000.0

func get_measure_precise() -> float:
	return RubiconTimeChange.get_measure_at_millisecond(get_time_changes(), get_time_precise())

func get_beat_precise() -> float:
	return RubiconTimeChange.get_beat_at_millisecond(get_time_changes(), get_time_precise())

func get_step_precise() -> float:
	return RubiconTimeChange.get_step_at_millisecond(get_time_changes(), get_time_precise())

func get_time_changes() -> Array[RubiconTimeChange]:
	if _level != null and _level.metadata != null:
		return _level.metadata.time_changes

	return []

func _validate_property(property: Dictionary) -> void :
	if property.name.begins_with("time_"):
		property.usage = PROPERTY_USAGE_EDITOR

func _process(delta: float) -> void :
	_current_frame_time = time_milliseconds
	_relative_time_offset = Time.get_unix_time_from_system()
	recalculate_cache()

	if step_change.has_connections():
		var cur_step: int = floori(time_step)
		if cur_step != _last_step:
			_last_step = cur_step
			step_change.emit()

	if beat_change.has_connections():
		var cur_beat: int = floori(time_beat)
		if cur_beat != _last_beat:
			_last_beat = cur_beat
			beat_change.emit()

	if measure_change.has_connections():
		var cur_measure: int = floori(time_measure)
		if cur_measure != _last_measure:
			_last_measure = cur_measure
			measure_change.emit()

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_READY:
			recalculate_cache()

		NOTIFICATION_PARENTED:
			if _level != null:
				_level.clock = null
				_level = null

			var parent: Node = get_parent()
			if parent is RubiconLevel:
				_level = parent

				if _level.clock == null:
					_level.clock = self
				else:
					printerr(tr("WARNING!! Having more than one RubiconLevelClock in a level can lead to problems!"))

				return

		NOTIFICATION_CHILD_ORDER_CHANGED:
			_animation_player = null
			for child in get_children():
				if child is AnimationPlayer:
					_animation_player = child
					break

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if level == null:
		warnings.append(tr("This node relies on being parented to a RubiconLevel! Please parent this node to a RubiconLevel node"))

	if _animation_player == null:
		warnings.append(tr("No AnimationPlayer child found! The clock relies on its first AnimationPlayer child to function."))

	return warnings

func recalculate_cache() -> void :
	_cached_measure = RubiconTimeChange.get_measure_at_millisecond(get_time_changes(), time_milliseconds)
	_cached_beat = RubiconTimeChange.get_beat_at_millisecond(get_time_changes(), time_milliseconds)
	_cached_step = RubiconTimeChange.get_step_at_millisecond(get_time_changes(), time_milliseconds)

	var changes: = get_time_changes()
	for change: RubiconTimeChange in changes:
		if change.measure <= time_measure:
			if _last_time_change != change:
				_last_time_change = change
				time_change_set.emit()
		else:
			break

static func measure_to_millisecond(measure: float, bpm: float, time_signature_numerator: float) -> float:
	return measure * ((60000.0 / bpm) * time_signature_numerator)

static func beats_to_millisecond(beat: float, bpm: float) -> float:
	return beat * (60000.0 / bpm)

static func steps_to_millisecond(step: float, bpm: float, time_signature_denominator: float) -> float:
	return step * (60000.0 / bpm / time_signature_denominator)

static func measure_to_beats(measure: float, time_signature_numerator: float) -> float:
	return measure * time_signature_numerator

static func measure_to_steps(measure: float, time_signature_numerator: float, time_signature_denominator: float) -> float:
	return beats_to_steps(measure_to_beats(measure, time_signature_numerator), time_signature_denominator)

static func beats_to_steps(beats: float, time_signature_denominator: float) -> float:
	return beats * time_signature_denominator

static func beats_to_measures(beats: float, time_signature_numerator: float) -> float:
	return beats / time_signature_numerator

static func steps_to_measures(steps: float, time_signature_numerator: float, time_signature_denominator: float) -> float:
	return steps / (time_signature_numerator * time_signature_denominator)
