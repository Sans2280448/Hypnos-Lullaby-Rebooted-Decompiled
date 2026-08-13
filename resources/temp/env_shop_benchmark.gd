extends Node3D
class_name ShopBenchmark

static var precache_shaders: bool

@export var animation_player: AnimationPlayer
@export var precache_anim_name: StringName = &"precache"
@export var cam_tour_anim_name: StringName = &"cam_tour"


func _ready() -> void :
	Debugger.fps_display.current_state = LullabyFPSDisplay.CurrentState.BASIC
	Debugger.fps_display.update_visibility()

	animation_player.play(precache_anim_name if precache_shaders else cam_tour_anim_name)
	animation_player.seek(0.0, true)

	if !precache_shaders:
		return

	await animation_player.animation_finished

	animation_player.play(cam_tour_anim_name)
	animation_player.seek(0.0, true)
