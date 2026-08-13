extends PhysicalBoneSimulator3D


@export var parent: Node3D


func _ready() -> void :
	if not parent:
		return

	parent.visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _on_visibility_changed() -> void :
	if not parent:
		return

	if parent.visible:
		physical_bones_start_simulation()
	else:
		physical_bones_stop_simulation()
