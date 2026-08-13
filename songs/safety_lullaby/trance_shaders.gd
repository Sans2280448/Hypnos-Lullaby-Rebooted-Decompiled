extends Node

@export var pendulum_server: LullabyPendulumServer

@onready var water: ShaderMaterial = %WaterEffect.material
@onready var hsv: ShaderMaterial = %HSVEffect.material
@onready var contrast: ShaderMaterial = %ContrastEffect.material
@onready var radial: ShaderMaterial = %RadialEffect.material

var _effects_strength: float = 0.0
var _nullify_strength: bool = false

func _process(delta: float) -> void :
	var target_strength = 0.0 if _nullify_strength else (100.0 - pendulum_server.retention_value) / 100.0
	_effects_strength = lerp(_effects_strength, target_strength, 1.0 - pow(0.2, delta))

	var water_amount = clamp(_effects_strength * 0.95, 0.0, 1.0)
	water.set_shader_parameter("WAVE_STRENGTH", min(EasingFunctions.ease_in_out_sine(0.0, 1.0, water_amount) * 0.95, 0.65))
	water.set_shader_parameter("GHOST_STRENGTH", min(EasingFunctions.ease_in_out_quad(0.0, 1.0, water_amount) * 0.25, 0.15))

	var saturation_amount = 1.0 - (_effects_strength * 0.275)
	hsv.set_shader_parameter("SATURATION", saturation_amount)

	var contrast_amount = 1.0 + (_effects_strength * 0.04575)
	contrast.set_shader_parameter("CONTRAST", contrast_amount)

	var radial_amount = _effects_strength * 0.135
	radial.set_shader_parameter("BLUR_STRENGTH", radial_amount)

func _on_lullaby_pendulum_server_mechanic_failed() -> void :
	_nullify_strength = true

func _on_health_module_health_depleted() -> void :
	_nullify_strength = true
