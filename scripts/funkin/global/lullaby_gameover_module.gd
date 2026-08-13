class_name LullabyGameoverModule
extends Node


static var last_song_path: String = ""
static var last_song_info: Dictionary

static var has_died: bool = false

@export var automatically_switch: bool = true
@export var health_module: RubiconHealthModule
@export var info: Dictionary

@export_file("*.tscn") var gameover_path: String


func _ready() -> void :
	if automatically_switch and health_module:
		health_module.health_depleted.connect(switch_to_gameover, CONNECT_ONE_SHOT)


func switch_to_gameover() -> void :
	if not gameover_path.is_empty():
		last_song_path = get_tree().current_scene.scene_file_path
		last_song_info = info
		get_tree().change_scene_to_file(gameover_path)
