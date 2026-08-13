extends Sprite2D



var light_strength: float = 1.0

var flicker_chance: float = 0.2

var flicker_time: float = 0.083
var deflicker_time: float = 0.083

enum FlickerState{FLICKER_STATE_NONE, FLICKER_STATE_FLICKER, FLICKER_STATE_DEFLICKER}
var flicker_state: FlickerState = FlickerState.FLICKER_STATE_NONE

var light_pulsating_range: float = 0.04
var bar_line_pulsating_range: float = 0.03

@export var lanes: Array[RubiconLevelManiaNoteHandler]
@export var lights: Array[PointLight2D]
@export var health_module: RubiconHealthModule

var health_tracked: float = 100.0

var time_passed: float = 0
var flicker_time_passed: float = 0

func _process(delta: float) -> void :
	if not Settings.get(&"game_flashing_lights"):
		return

	health_tracked = lerp(health_tracked, health_module.health, 20 * delta)

	var health_progress: float = float(health_tracked) / float(health_module.max_health)
	light_strength = calculate_light_strength(health_progress)
	time_passed += delta

	if flicker_state != FlickerState.FLICKER_STATE_NONE:
		return

	pulsate_lights()

func _physics_process(delta: float) -> void :
	if not Settings.get(&"game_flashing_lights"):
		return

	if flicker_state != FlickerState.FLICKER_STATE_NONE:
		flicker_time_passed += delta

		if flicker_time_passed >= flicker_time and flicker_state == FlickerState.FLICKER_STATE_FLICKER:
			deflicker_lights()

		if flicker_time_passed >= deflicker_time and flicker_state == FlickerState.FLICKER_STATE_DEFLICKER:
			flicker_state = FlickerState.FLICKER_STATE_NONE
			pulsate_lights()

		return

	var health_progress: float = float(health_tracked) / float(health_module.max_health)
	flicker_chance = 0.05 + ((1 - health_progress) * 2.5)
	if randf_range(0, 100) < flicker_chance:
		flicker_lights()

func calculate_light_strength(progress: float) -> float:
	return 1 - pow(1 - progress, 3)

func flicker_lights() -> void :
	flicker_state = FlickerState.FLICKER_STATE_FLICKER
	flicker_time_passed = 0

	var bar_line_darkness: float = max(light_strength - 0.1, 0.1)

	for lane in lanes:
		lane.modulate = Color(bar_line_darkness, bar_line_darkness, bar_line_darkness, lane.modulate.a)

	var light_energy: float = max(((light_strength - light_pulsating_range) * 0.8) - 0.1, 0.1)
	for light in lights:
		light.energy = light_energy

func deflicker_lights() -> void :
	flicker_state = FlickerState.FLICKER_STATE_DEFLICKER
	flicker_time_passed = 0.0

	for lane in lanes:
		lane.modulate = Color(1.0, 1.0, 1.0, lane.modulate.a)
	for light in lights:
		light.energy = 0.8

func pulsate_lights() -> void :
	var pulse_progress: float = sin(time_passed * PI)

	var bar_line_darkness: float = max(light_strength + (pulse_progress * bar_line_pulsating_range) - bar_line_pulsating_range, 0.2)
	for lane in lanes:
		lane.modulate = Color(bar_line_darkness, bar_line_darkness, bar_line_darkness, lane.modulate.a)

	var light_energy: float = max((0.8 * light_strength) + (pulse_progress * light_pulsating_range) - light_pulsating_range, 0.0)
	for light in lights:
		light.energy = light_energy
