extends Node


@export var health_module: RubiconHealthModule
@export var death_scene: PackedScene

@export var phase_two_gold: RubiconCharacter;

@export var death_enabled: bool = true
@export var anim_player: AnimationPlayer

@export var clock: RubiconLevelClock

func _ready() -> void :
	if health_module and death_enabled:
		health_module.health_depleted.connect( func():
			LullabyGameoverModule.has_died = true
			MonochromeGameover.skip_first_part = !phase_two_gold.visible
			change_scene();
			, CONNECT_ONE_SHOT)

func change_scene():
	get_tree().change_scene_to_packed(death_scene)
