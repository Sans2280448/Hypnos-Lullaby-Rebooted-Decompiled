extends Camera3D

@export var animation_player: AnimationPlayer
@export var animation_name: StringName
@export var camera_to_focus: Camera3D

func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS

	if !SceneChanger.awaiting_manual_end:
		finish_preload()
		return

	visible = true
	make_current()
	animation_player.play(animation_name)

	animation_player.animation_finished.connect(finish_preload)

func finish_preload(_anim: StringName = &"") -> void :
	if camera_to_focus != null and !camera_to_focus.current:
		camera_to_focus.make_current()

	if SceneChanger.awaiting_manual_end:
		SceneChanger.finish_loading_screen()
	queue_free()
