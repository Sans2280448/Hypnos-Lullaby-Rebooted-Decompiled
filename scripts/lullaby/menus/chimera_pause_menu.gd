class_name ChimeraPauseMenu extends Control

const SHAKY_CAMERA_SCENE: PackedScene = preload("res://addons/mrminimal_camera_shake/shaky_camera.tscn")

@export var level: RubiconLevel
@export var active: bool = false
@export var paused: bool = false
@export var can_exit: bool = false
@export var credits_shown: bool = false
@export var camera: Camera3D
@export var exit_button: Control
@export var no_exit_text: Control
@export var music: AudioStreamPlayer

var _camera_3d: Camera3D
var _shaky_camera: Node3D

func resume() -> void :
	music.stop()
	release_focus()

	_shaky_camera.queue_free()
	camera.make_current()

	get_tree().paused = false
	paused = false

func restart() -> void :
	music.stop()
	release_focus()
	SceneChanger.change_to(get_tree().current_scene.scene_file_path, &"hypno")

func credits() -> void :
	credits_shown = true
	release_focus()

func hide_credits() -> void :
	credits_shown = false
	release_focus()

func exit() -> void :
	ChimeraGameoverModule.deaths = 0
	release_focus()
	SceneChanger.change_to("res://rooms/env_collector_shop.tscn", &"hypno", true)

func _input(event: InputEvent) -> void :
	if not active:
		return

	if not event.is_action_pressed("funkin_pause"):
		return

	var tree: SceneTree = get_tree()
	if tree.paused:
		return

	tree.paused = true
	paused = true

	if level and level.metadata.title.to_lower() == "chimera":
		var allow_exit: bool = true
		if SaveData.get_flag(&"chimera_2nd_phase_first") and not SaveData.get_flag(&"chimera_beaten"):
			allow_exit = false

		no_exit_text.visible = not allow_exit
		exit_button.focus_mode = Control.FOCUS_ALL if allow_exit else Control.FOCUS_NONE
	else:
		no_exit_text.visible = false

	if camera == null:
		return

	_camera_3d = camera.duplicate()
	_camera_3d.name = &"Camera"

	for child in _camera_3d.get_children():
		child.queue_free()

	_shaky_camera = SHAKY_CAMERA_SCENE.instantiate()
	add_child(_shaky_camera)

	_shaky_camera.global_transform = camera.global_transform
	_shaky_camera.get_node("Camera").replace_by(_camera_3d)
	_camera_3d.position = Vector3.ZERO
	_camera_3d.rotation = Vector3.ZERO

	_camera_3d.make_current()
