class_name CollectorBriefcaseCartridge
extends BoneAttachment3D


@export var key: StringName
@export var voiceline_group: String = "shop_hovermono"

@export var animation_offset: Node3D
@export var cartridge_mesh: MeshInstance3D

@export_group("Collision References")
@export var area: Area3D
@export var area_collision: CollisionShape3D

@export_group("Animation References")
@export var hover_anims: AnimationPlayer
@export var float_anims: AnimationPlayer
@export var material_anims: AnimationPlayer
@export var dissolve_anims: AnimationPlayer


func _ready() -> void :
	if key.is_empty():
		key = name.to_snake_case()

	visible = not SaveData.get_flag(&"%s_unlocked" % key)
	process_mode = (
		Node.PROCESS_MODE_DISABLED if SaveData.get_flag(&"%s_unlocked" % key)
		else Node.PROCESS_MODE_INHERIT
	)
