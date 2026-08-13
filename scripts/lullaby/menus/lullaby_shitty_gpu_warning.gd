extends Control

@export var focus_first: Control
@export var poop_sound: AudioStreamPlayer

func _ready() -> void :
	focus_first.grab_focus()

func request_continue() -> void :
	SaveData.set_meta(&"angle_seen", true)
	get_tree().change_scene_to_file("res://rooms/scn_boot.tscn")

func request_back() -> void :
	poop_sound.play()

	var tree: SceneTree = get_tree()
	tree.paused = true
	await tree.create_timer(0.1, true).timeout

	tree.quit()
