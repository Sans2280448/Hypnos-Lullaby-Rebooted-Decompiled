@tool
extends Node
class_name RubiconCameraBumper

enum BumpTime{
	STEP, 
	BEAT, 
	MEASURE, 
}

@export var enabled: bool = true

@export var bump_every: BumpTime = BumpTime.MEASURE:
	set(value):
		bump_every = value
		set_bump_time(value)

@export_range(1, 128) var bump_interval: int = 1

@export var bump_amount: float = 0.05

var _level: RubiconLevel:
	set(value):
		_level = value
		set_bump_time(bump_every)

var _camera_2d: RubiconInterpolatedCamera2D
var _camera_3d: RubiconInterpolatedCamera3D

func _init() -> void :
	set_process_internal(true)

func is_attached_to_2d_camera() -> bool:
	return _camera_2d != null

func is_attached_to_3d_camera() -> bool:
	return _camera_3d != null

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_PARENTED:
			var parent: Node = get_parent()
			if parent is RubiconInterpolatedCamera2D:
				_camera_2d = parent
			elif parent is RubiconInterpolatedCamera3D:
				_camera_3d = parent

			while parent != null:
				if parent is RubiconLevel:
					_level = parent
					break

				parent = parent.get_parent()
		NOTIFICATION_UNPARENTED:
			_camera_2d = null
			_camera_3d = null
			_level = null

func set_bump_time(new_bump_time: BumpTime):
	if _level == null:
		return

	match bump_every:
		BumpTime.STEP:
			if _level.clock.beat_change.is_connected(camera_bump):
				_level.clock.beat_change.disconnect(camera_bump)

			if _level.clock.measure_change.is_connected(camera_bump):
				_level.clock.measure_change.disconnect(camera_bump)

			if !_level.clock.step_change.is_connected(camera_bump):
				_level.clock.step_change.connect(camera_bump)

		BumpTime.BEAT:
			if _level.clock.step_change.is_connected(camera_bump):
				_level.clock.step_change.disconnect(camera_bump)

			if _level.clock.measure_change.is_connected(camera_bump):
				_level.clock.measure_change.disconnect(camera_bump)

			if !_level.clock.beat_change.is_connected(camera_bump):
				_level.clock.beat_change.connect(camera_bump)

		BumpTime.MEASURE:
			if _level.clock.step_change.is_connected(camera_bump):
				_level.clock.step_change.disconnect(camera_bump)

			if _level.clock.beat_change.is_connected(camera_bump):
				_level.clock.beat_change.disconnect(camera_bump)

			if !_level.clock.measure_change.is_connected(camera_bump):
				_level.clock.measure_change.connect(camera_bump)

func camera_bump() -> void :
	var cur_time: int = floorf(get_cur_time_value())
	if cur_time % bump_interval != 0:
		return

	if _camera_2d != null:
		_camera_2d.zoom += Vector2(bump_amount, bump_amount)
	if _camera_3d != null:
		_camera_3d.fov += bump_amount

func get_cur_time_value() -> float:
	match bump_every:
		BumpTime.BEAT:
			return _level.clock.time_beat
		BumpTime.STEP:
			return _level.clock.time_step
	return _level.clock.time_measure
