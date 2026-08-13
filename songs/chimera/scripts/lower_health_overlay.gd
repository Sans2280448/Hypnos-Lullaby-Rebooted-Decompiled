
extends Node
class_name ChimeraLowerHealthModule

@export var health_module: RubiconHealthModule
@export var color_rect: ColorRect

func _ready() -> void :
	if is_instance_valid(health_module):
		health_module.health_changed.connect(_on_health_changed)

func _on_health_changed() -> void :
	if is_instance_valid(color_rect):
		color_rect.visible = health_module.health < health_module.max_health / 2
		if color_rect.visible:
			color_rect.self_modulate.a = remap(health_module.health, health_module.min_health, health_module.max_health / 2, 1, 0)
