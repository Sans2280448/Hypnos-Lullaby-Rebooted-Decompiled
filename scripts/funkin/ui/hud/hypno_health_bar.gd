@tool
class_name HypnoHealthBar extends Control



const NEUTRAL: StringName = &"neutral"
const WINNING: StringName = &"win"
const LOSING: StringName = &"lose"
const TO_WINNING: StringName = &"toWin"
const TO_LOSING: StringName = &"toLose"
const FROM_WINNING: StringName = &"fromWin"
const FROM_LOSING: StringName = &"fromLose"


@export var size_lerp_weight: float = 3.6

@export_group("Time", "time_")

@export_enum("Measure", "Beat", "Step") var time_type: String = "Measure"
@export var time_interval: float = 1.0

@export_group("References")
@export var health_module: RubiconHealthModule
@export var progress_bar: TextureProgressBar
@export var left_icon: AnimatedSprite2D
@export var right_icon: AnimatedSprite2D
@export var icon_container: PathFollow2D

var _level: RubiconLevel
var _clock: RubiconLevelClock


func _notification(what: int) -> void :
	match what:
		NOTIFICATION_PARENTED, NOTIFICATION_READY:
			var parent: Node = get_parent()
			while parent != null and _level == null:
				if parent is RubiconLevel:
					_level = parent
					_clock = _level.clock
				else:
					parent = parent.get_parent()


func _process(_delta: float) -> void :
	if health_module:
		var health: float = health_module.health
		var min_health: float = health_module.min_health
		var max_health: float = health_module.max_health
		var health_ratio: float = (health - min_health) / (max_health - min_health)

		if icon_container:
			icon_container.progress_ratio = 1.0 - health_ratio
		progress_bar.ratio = health_ratio

		var player_winning: = health_ratio > 0.8
		var player_losing: = health_ratio < 0.2

		if left_icon:
			_update_icon_animation(left_icon, player_winning, player_losing)
		if right_icon:
			_update_icon_animation(right_icon, player_losing, player_winning)

	if _clock and _clock._last_time_change:
		_update_icon_scale()


func _update_icon_animation(icon: AnimatedSprite2D, losing: bool = false, winning: bool = false) -> void :
	var current_anim: StringName = icon.animation
	var mid_animation: Array[StringName] = [
		TO_WINNING, 
		TO_LOSING, 
		FROM_WINNING, 
		FROM_LOSING, 
	]

	if mid_animation.has(current_anim):
		return

	var animation: StringName = NEUTRAL
	var frames: SpriteFrames = icon.sprite_frames
	if losing:
		if frames.has_animation(TO_LOSING):
			animation = TO_LOSING
		elif frames.has_animation(LOSING):
			animation = LOSING
	elif winning:
		if frames.has_animation(TO_WINNING):
			animation = TO_WINNING
		elif frames.has_animation(WINNING):
			animation = WINNING
	else:
		if current_anim == WINNING and frames.has_animation(FROM_WINNING):
			animation = FROM_WINNING
		elif current_anim == LOSING and frames.has_animation(FROM_LOSING):
			animation = FROM_LOSING

	if not frames.has_animation(current_anim):
		return

	icon.play(animation)


func _update_icon_scale() -> void :
	var lerp_ratio: float = 0.0
	match time_type:
		"Measure":
			lerp_ratio = fmod(
				_clock.time_measure * _clock._last_time_change.time_signature_numerator, 
				time_interval * _clock._last_time_change.time_signature_numerator
			)
		"Beat":
			lerp_ratio = fmod(_clock.time_beat, time_interval)
		"Step":
			lerp_ratio = fmod(
				_clock.time_step / _clock._last_time_change.time_signature_denominator, 
				time_interval / _clock._last_time_change.time_signature_denominator
			)

	if left_icon:
		left_icon.scale = Vector2.ONE * lerpf(
			1.2, 
			1.0, 
			clampf(lerp_ratio * size_lerp_weight, 0.0, 1.0)
		)
	if right_icon:
		right_icon.scale = Vector2( - left_icon.scale.x, left_icon.scale.y)
