extends Node3D


@export var song_name: String
@export var outline_shader: ShaderMaterial
@onready var seen_already: bool = SaveData.get_flag("seen_%s_prop" % song_name)

@export var mesh: MeshInstance3D

var default_material: Material

func _ready() -> void :
	if mesh:
		default_material = mesh.material_overlay
	visible = SaveData.has_passed_song(song_name)

	if ( not seen_already) and mesh and outline_shader:
		mesh.material_overlay = outline_shader


func remove_material() -> void :
	if not seen_already:
		SaveData.set_flag("seen_%s_prop" % song_name, true)

	if mesh:
		mesh.material_overlay = default_material
