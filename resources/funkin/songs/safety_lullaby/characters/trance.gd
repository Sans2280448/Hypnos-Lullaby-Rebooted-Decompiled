extends Node

@export var gf_pose_switcher: AnimationPlayer
@export var pendulum_server: LullabyPendulumServer
@export var trance_overlay: AnimatedSprite2D
@export var health_module: Node
@export var gf_is_calm: = true

var target_transparency: float = 0.0

func _ready() -> void :
	trance_overlay.modulate.a = 0.0

func _process(delta: float) -> void :
	var retention: float = float(pendulum_server.retention_value)
	if retention <= 60.0 and retention > 0.0:
		if gf_pose_switcher.current_animation != &"trance":
			gf_pose_switcher.play(&"trance")

		target_transparency = clamp((60.0 - retention) / 60.0 / 2, 0.0, 1.0)
	else:
		if health_module.health > 0:
			var anim_name: = &"initial" if gf_is_calm else &"regular"

			if gf_pose_switcher.current_animation != anim_name:
				gf_pose_switcher.play(anim_name)

		target_transparency = 0.0

	trance_overlay.modulate.a = lerp(
		trance_overlay.modulate.a, 
		target_transparency, 
		1.0 - pow(0.2, delta * 2.0)
	)
