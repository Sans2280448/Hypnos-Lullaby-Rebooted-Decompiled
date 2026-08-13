@tool
class_name LullabyPendulumServer extends Node


const META_NAME: StringName = &"lullaby_special"

@export var rotation: float = 0.0
@export var rotation_length: float = deg_to_rad(107.5)

@export var linear_rotation_ratio: float = 0.0

@export var dropped: bool = false:
	get:
		return dropped
	set(val):
		var changed: bool = val != dropped
		dropped = val

		if changed:
			drop_changed.emit()

@export var started: bool = false:
	get:
		return started
	set(val):
		var changed: bool = val != started
		started = val

		if changed:
			if val:
				_update_hit_time()
				_update_rotation()

			set_process_internal(val)
			start_changed.emit()

@export var autoplay: bool = false


@export_group("Retention", "retention_")
@export var retention_value: int = 100
@export var retention_max: int = 100
@export var retention_gain: int = 15
@export var retention_loss: int = -15

@export_group("Input", "input_")
@export var input_action: StringName = &"lullaby_special"
@export var input_hit_window_ms: float = 75.0

signal drop_changed
signal hit_time_changed(hit_time: float)
signal start_changed

signal pendulum_hit
signal pendulum_success
signal pendulum_missed

signal mechanic_failed

var _level: RubiconLevel
var _next_hit_ms: float = 0.0

var _pendulum_is_hit: bool = false
var _pendulum_measure: int = 0

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_READY:
			retention_value = retention_max
		NOTIFICATION_EDITOR_PRE_SAVE:
			if _level != null:
				_level.remove_meta(META_NAME)
		NOTIFICATION_EDITOR_POST_SAVE:
			if _level != null:
				_level.set_meta(META_NAME, self)
		NOTIFICATION_PARENTED:
			var parent: Node = get_parent()
			while parent != null and _level == null:
				if parent is RubiconLevel:
					_level = parent

					_level.set_meta(META_NAME, self)
					_level.emit_changed()
				else:
					parent = parent.get_parent()
		NOTIFICATION_UNPARENTED:
			if _level != null:
				_level.remove_meta(META_NAME)
				_level.emit_changed()

			_level = null
		NOTIFICATION_INTERNAL_PROCESS:
			if not started:
				return

			var clock: RubiconLevelClock = _level.clock
			if clock == null:
				return

			_update_rotation()

			if retention_value <= 0.0:
				mechanic_failed.emit()
				return

			var pendulum_hittable: bool = is_hittable()
			if pendulum_hittable and not _pendulum_is_hit and autoplay:
				hit_pendulum()

			var current_measure: int = floori(clock.time_measure * 2.0)
			if _pendulum_measure != current_measure and not pendulum_hittable:
				_pendulum_measure = current_measure

				if not _pendulum_is_hit:
					retention_value = clampi(retention_value + retention_loss, 0, retention_max)
					pendulum_hit.emit()
					pendulum_missed.emit()

				_pendulum_is_hit = false
				_update_hit_time()

func _input(event: InputEvent) -> void :
	if autoplay:
		return

	if not event.is_action_pressed(input_action):
		return

	if not started or _pendulum_is_hit:
		return

	hit_pendulum()

func is_hittable() -> bool:
	if _level == null:
		return false

	var clock: RubiconLevelClock = _level.clock
	if clock == null:
		return false

	return absf(_next_hit_ms - clock.time_milliseconds) <= input_hit_window_ms

func hit_pendulum() -> void :
	_pendulum_is_hit = true
	var is_pendulum_hittable: bool = is_hittable()
	var change: int = retention_gain if is_pendulum_hittable else retention_loss

	retention_value = clampi(retention_value + change, 0, retention_max)

	pendulum_hit.emit()
	if is_pendulum_hittable:
		pendulum_success.emit()
	else:
		pendulum_missed.emit()

func _update_hit_time() -> void :
	if _level == null:
		return

	var clock: RubiconLevelClock = _level.clock
	if clock == null:
		return

	var time_change: RubiconTimeChange = RubiconTimeChange.get_time_change_at_millisecond(_level.metadata.time_changes, clock.time_milliseconds)
	var next_hit_measure: float = snapped(clock.time_measure + 0.5, 0.5)
	var measure_value: float = RubiconLevelClock.measure_to_millisecond(1.0, time_change.bpm, time_change.time_signature_numerator)
	_next_hit_ms = time_change.millisecond_time + (measure_value * (next_hit_measure - time_change.measure))

	hit_time_changed.emit(_next_hit_ms)

func _update_rotation() -> void :
	if _level == null:
		return

	var clock: RubiconLevelClock = _level.clock
	if clock == null:
		return

	var rot_base_amount: float = sin(clock.time_measure * 2.0 * PI)
	var rot_base_normal: float = (rot_base_amount + 1.0) / 2.0

	var rot_base_eased: float = rot_base_normal * linear_rotation_ratio
	rot_base_eased += EasingFunctions.ease_in_out_quad(0.0, 1.0, rot_base_normal) * (1.0 - linear_rotation_ratio)

	var rot_base_corrected: float = (rot_base_eased * 2.0) - 1.0
	var rot_final: float = rot_base_corrected * 0.825

	rot_final *= -1.0

	rotation = rot_final
