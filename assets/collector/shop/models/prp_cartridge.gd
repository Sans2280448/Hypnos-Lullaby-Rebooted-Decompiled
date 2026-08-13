extends Node3D

@export var texture: String
@export var anim: AnimationPlayer

func _ready() -> void :
	anim.play("materials/%s" % texture)
