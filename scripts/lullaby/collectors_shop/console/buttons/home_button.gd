class_name ConsoleHomeButton
extends Control


@export var disabled: bool = false

@export var home_container: HomeContainer
@export var tab_target: Control
@export var icon_model: Node3D
@export var icon_mesh: Node3D
@export var icon_animation_player: AnimationPlayer
@export var idle_animation: StringName
@export var select_animation: StringName
@export var console: Console
@export var material_idle: StandardMaterial3D
@export var material_select: StandardMaterial3D

var focused: bool = false
var tween: Tween


func _ready() -> void :
	focus_entered.connect(_focus_entered)
	focus_exited.connect(_focus_exited)
	home_container.disable_icons.connect(_disable_icons)
	home_container.enable_icons.connect(_enable_icons)

func _focus_entered() -> void :
	home_container.bubble_target = position + pivot_offset

	if icon_mesh is MeshInstance3D:
		icon_mesh.mesh.surface_set_material(0, material_select)
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(icon_mesh, "scale", Vector3(1.1, 1.1, 1.1), 0.25).set_trans(Tween.TRANS_CUBIC)
	focused = true

func _focus_exited() -> void :
	console.play_sound.emit("sfx_soulroom_click")

	if icon_mesh is MeshInstance3D:
		icon_mesh.mesh.surface_set_material(0, material_idle)
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(icon_mesh, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_CUBIC)
	focused = false

func _input(event: InputEvent) -> void :
	if console.booting:
		return

	if event.is_action_released(&"ui_accept") and focused:
		if disabled:
			console.play_sound.emit("sfx_soulroom_deny")
			return
		focused = false
		icon_animation_player.play(select_animation)
		home_container.disable_icons.emit()
		console.play_sound.emit("sfx_soulroom_select_alt")
		icon_animation_player.animation_finished.connect( func(_anim: StringName):
			home_container.tab_container.change_tab(tab_target.get_index())
		, CONNECT_ONE_SHOT)

func _disable_icons():
	if has_focus():
		return
	focus_mode = Control.FOCUS_NONE


func _enable_icons():
	focus_mode = Control.FOCUS_ALL
