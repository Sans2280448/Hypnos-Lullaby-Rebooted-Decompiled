@tool
extends Node
class_name HeartbeatController

@export_tool_button("Start Beating") var start_playtest = initialize
@export_tool_button("Stop Beating") var stop_playtesting = stop

@export var autoplay: bool = false
@export var verbose: bool = false

@export_group("Beating Settings", "beating_")
@export var beating_time_until_reset: float = 0.08
@export_subgroup("Hit Window", "beating_")
@export var beating_hit_window: float = 0.15
@export var beating_rate_below_threshold: float = 0.5
@export var beating_lose_threshold: float = 4
@export var beating_threshold_immunity: float = 0.5

@export_subgroup("Input", "beating_")
@export var beating_input_map: StringName = &"lullaby_special"
@export var beating_success_add: float = 0.025
@export var beating_fail_add: float = -0.075

@export_subgroup("Speed", "beating_")
@export var beating_starting_time_seconds: float = 1.0656
@export var beating_minimum_rate: float = 0.35
@export var beating_maximum_rate: float = 1.0

@export_group("Line", "line_")
@export var line_start: float = -400.0
@export var line_end: float = 400.0
@export var line_ready: float = -225.0
@export var line_points: Array[Vector2] = [Vector2(-20, 0), Vector2(-10, -60), Vector2(10, 60), Vector2(20, 0)]
@export var line_scale_small: float = 0.4
@export var line_scale_big: float = 1.0
@export var line_reference: Line2D
@export var line_curve: Curve

@export_group("Animation Settings", "animation_")
@export var animation_beat: StringName = &"lbr_serena_heart/Chimera_Heartbeat_Final"
@export var animation_speed_offset: float = 0.5

@export_group("References")
@export var animation_player: AnimationPlayer
@export var heartbeat: Sprite2D
@export var vignette: TextureRect
@export var heart_sprite: AnimatedSprite2D

var beating_enabled: bool = false
var beating_rate: float = 1.0
var beating_timer: float = 0.0
var beating_starting_rate: float = 1.0

var has_beaten: bool = false
var can_hit: bool = false
var miss_streak: int = 0
var time_under_threshold: float = 0.0
var threshold_immunity: float = 0.0
var starting_miss_immunity: int = 3

var beats_successful: int = 0
var total_beats: int = 0

var completing_cycle: bool = false

var _line_color_tween: Tween

var _autoplay: bool:
	get:
		return autoplay and !Engine.is_editor_hint()


signal mechanic_failed

func initialize() -> void :
	if verbose:
		print("Started heartbeat.")

	beating_enabled = true
	completing_cycle = false
	beating_rate = beating_starting_rate
	time_under_threshold = 0.0
	threshold_immunity = beating_threshold_immunity

	reset_timer()

func stop() -> void :
	if verbose:
		print("Stopped heartbeat")

	beating_enabled = false
	completing_cycle = false

	reset_timer()

func _input(event: InputEvent) -> void :
	if _autoplay or completing_cycle:
		return

	if !event.is_action_pressed(beating_input_map):
		return

	if can_hit:
		heart_beat()
		complete_cycle(true)
	else:
		missed_beat()

var shader_value_bullshit: float = 1.0

func weight_size(x: float):
	return x ** 0.25

func _process(delta: float) -> void :
	_update_line()

	if beating_enabled:
		shader_value_bullshit = lerpf(shader_value_bullshit, beating_rate, 0.05)
		heart_sprite.material.set("shader_parameter/saturation", shader_value_bullshit)

	if !beating_enabled:
		return

	beating_timer -= delta

	if completing_cycle:
		return

	can_hit = abs(beating_timer) <= beating_hit_window

	if beating_timer <= 0.0 and !has_beaten:
		heart_beat()

	if _autoplay and beating_timer < 0.0:
		complete_cycle(true)
		return
	elif beating_timer <= - beating_hit_window:
		complete_cycle(false)
		return

	if beating_rate <= beating_rate_below_threshold:
		if threshold_immunity > 0.0:
			threshold_immunity -= delta
		else:
			time_under_threshold += delta

			if time_under_threshold >= beating_lose_threshold:
				mechanic_failed.emit()
				if verbose:
					print("Failed Mechanic, game should stop.")

func complete_cycle(success: bool) -> void :
	if completing_cycle:
		return

	completing_cycle = true

	beating_timer = 0.0
	await get_tree().create_timer(beating_time_until_reset).timeout

	total_beats += 1

	if !beating_enabled:
		completing_cycle = false
		return

	if success:
		successful_beat()
	else:
		missed_beat()

	reset_timer()

	completing_cycle = false

func reset_timer() -> void :
	can_hit = false
	has_beaten = false
	beating_timer = beating_starting_time_seconds * beating_rate

	if verbose:
		print("Reset Timer at time: %s, Beating rate: %s" % [str(beating_timer), str(beating_rate)])

var vignette_tween = create_tween()
func heart_beat() -> void :
	has_beaten = true

	if verbose:
		print("Beat Heart, New rate: %s" % [str(beating_rate)])

	if animation_player != null:
		animation_player.speed_scale = (1.0 - beating_rate) + animation_speed_offset
		animation_player.play(animation_beat)
		animation_player.seek(0.0, true)

		if not vignette:
			return

		if vignette_tween.is_running():
			vignette_tween.kill()
		vignette.modulate.a = snappedf(1 - beating_rate, 0.01)
		vignette_tween = create_tween()
		vignette_tween.tween_property(vignette, "modulate:a", 0, 0.5)



func successful_beat() -> void :
	if verbose:
		print("Success! Gigi murin")

	starting_miss_immunity = 0
	miss_streak = 0

	beats_successful += 1

	line_reference.default_color = Color.WHITE
	if _line_color_tween and _line_color_tween.is_running():
		_line_color_tween.kill()

	_line_color_tween = line_reference.create_tween()
	_line_color_tween.tween_property(line_reference, "default_color", Color.DARK_GRAY, 0.5)
	_line_color_tween.play()

	if beating_rate > beating_rate_below_threshold:
		beating_lose_threshold = 0

	beating_rate = clampf(
		beating_rate + beating_success_add, 
		beating_minimum_rate, 
		beating_maximum_rate
	)

func missed_beat() -> void :
	if verbose:
		print("Fail :(")

	line_reference.default_color = Color.RED
	if _line_color_tween and _line_color_tween.is_running():
		_line_color_tween.kill()

	_line_color_tween = line_reference.create_tween()
	_line_color_tween.tween_property(line_reference, "default_color", Color.DARK_GRAY, 0.5)
	_line_color_tween.play()

	if starting_miss_immunity > 0:
		starting_miss_immunity -= 1
		return

	miss_streak += 1

	if miss_streak >= 2:
		beating_rate = clampf(
			beating_rate + beating_fail_add, 
			beating_minimum_rate, 
			beating_maximum_rate
		)

func _update_line() -> void :
	if not beating_enabled:
		_update_points(0.0, 1.0)
		return

	var max_time: float = beating_starting_time_seconds * beating_rate
	var ratio: float = beating_timer / max_time


	var ease_ratio: float = line_curve.sample(1.0 - clampf(ratio, 0.0, 1.0))
	if not completing_cycle:
		var before_offset: float = line_start + ((line_ready - line_start) * ease_ratio)
		_update_points(before_offset, ease_ratio * line_scale_small)
		return

	var after_ratio: float = clampf( - (beating_timer / beating_time_until_reset), 0.0, 1.0)
	var after_offset: float = line_end * after_ratio
	_update_points(after_offset, 0.5 + ((line_scale_big - 0.5) * (1.0 - after_ratio)))

func _update_points(offset: float = 0.0, scale: float = 1.0) -> void :
	line_reference.set_point_position(0, Vector2(line_start, 0.0))

	for i in range(0, 4):
		var point: Vector2 = line_points[i]
		point.y *= scale
		point.x += offset

		line_reference.set_point_position(i + 1, point)

	line_reference.set_point_position(5, Vector2(line_end, 0.0))
