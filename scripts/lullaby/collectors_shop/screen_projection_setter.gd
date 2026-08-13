extends MeshInstance3D

@export var viewport: SubViewport
@export var material_override_idx: int = 0

func _ready() -> void :
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.resource_local_to_scene = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var viewport_tex: ViewportTexture = ViewportTexture.new()
	viewport_tex.viewport_path = get_path_to(viewport)
	mat.albedo_texture = viewport_tex

	set_surface_override_material(material_override_idx, mat)
