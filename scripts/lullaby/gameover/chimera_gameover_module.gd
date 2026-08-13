class_name ChimeraGameoverModule
extends Node


static var deaths: int = 0

@export var ignore_for_skips: bool = false
@export var health_module: RubiconHealthModule
@export var track_deaths: bool = false

@export var paths: Dictionary[StringName, String] = {}

@onready var timer: Timer = $Timer

var path_key: StringName = &""


func _ready() -> void :
	if health_module:
		health_module.health_depleted.connect(switch_to_gameover, CONNECT_ONE_SHOT)


func switch_to_gameover() -> void :
	if ignore_for_skips:
		return

	LullabyGameoverModule.has_died = true

	if track_deaths:
		deaths += 1
		path_key = &"step_%d" % clampi(deaths, 1, 4)
	else:
		path_key = &"step_0"

	if not paths[path_key].is_empty():
		get_tree().change_scene_to_file(paths[path_key])
