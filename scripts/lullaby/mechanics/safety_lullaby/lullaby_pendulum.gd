@tool
class_name LullabyPendulum extends Control

@export var pendulum: Node2D
@export var pendulum_trail: Node2D
@export var pendulum_anchor: Node2D
@export var pendulum_strength: float = 4.0
@export var pendulum_bob: bool = false
@export var pendulum_y_offset: float = 0.0

@export_group("Animations", "animation_")
@export var animation_player: AnimationPlayer
@export var animation_drop: StringName = &"drop"
@export var animation_hide: StringName = &"RESET"
@export var animation_hit: StringName = &"hit"
@export var animation_missed: StringName = &"miss"

var _level: RubiconLevel
var _server: LullabyPendulumServer

var _time_passed: float = 0.0

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_PARENTED, NOTIFICATION_READY:
			var parent: Node = get_parent()
			while parent != null and _level == null:
				if parent is RubiconLevel:
					_level = parent
					_level.changed.connect(_level_changed)
					_level_changed()
				else:
					parent = parent.get_parent()

		NOTIFICATION_UNPARENTED:
			if _level != null:
				_level.changed.disconnect(_level_changed)

			_level = null
			_level_changed()
		NOTIFICATION_INTERNAL_PROCESS:
			pendulum.rotation = _server.rotation * (pendulum_strength / 4.0)

			_time_passed += get_process_delta_time()

			if pendulum_bob:
				if _level == null:
					return

				var clock: RubiconLevelClock = _level.clock
				if clock == null:
					return

				var next_pendulum_x = sin(clock.time_measure * 2.0 * PI) * (pendulum_strength * 0.75)




				var next_pendulum_y = cos(_time_passed) * (pendulum_strength * 0.8)
				next_pendulum_y += sin(_time_passed) * (pendulum_strength * 0.8)
				next_pendulum_y += pendulum_y_offset

				next_pendulum_x += randf() * 0.5;
				next_pendulum_y += randf() * 0.5;

				var lerp_ratio = 1.0 - pow(0.1, get_process_delta_time())
				pendulum_anchor.position.x = lerp(pendulum_anchor.position.x, next_pendulum_x, lerp_ratio)
				pendulum_anchor.position.y = lerp(pendulum_anchor.position.y, next_pendulum_y, lerp_ratio)

func _level_changed() -> void :
	set_process_internal(false)

	if _server != null:
		_server.drop_changed.disconnect(_on_drop_changed)
		_server.start_changed.disconnect(_on_start_changed)
		_server.pendulum_success.disconnect(_on_success)

	if _level == null or not _level.has_meta(LullabyPendulumServer.META_NAME):
		_server = null
		return

	_server = _level.get_meta(LullabyPendulumServer.META_NAME)
	_server.drop_changed.connect(_on_drop_changed)
	_server.start_changed.connect(_on_start_changed)
	_server.pendulum_success.connect(_on_success)

	_on_drop_changed()
	_on_start_changed()

func _on_drop_changed() -> void :
	if _server.dropped:
		if not animation_drop.is_empty():
			animation_player.play(animation_drop)
	else:
		if not animation_hide.is_empty():
			animation_player.play(animation_hide)

func _on_start_changed() -> void :
	set_process_internal(_server.started)

func _on_success() -> void :
	pendulum_trail.rotation = _server.rotation
	if not animation_hit.is_empty():
		animation_player.play(animation_hit)
