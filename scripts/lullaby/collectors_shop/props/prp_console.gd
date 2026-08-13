extends Node3D


@export var cartridge_materials: AnimationPlayer


func _ready() -> void :
	update_cartridge(SaveData.cartridge_selected)
	SaveData.new_cartridge_selected.connect(update_cartridge)


func update_cartridge(cart: StringName) -> void :
	cartridge_materials.play(&"materials/%s" % cart)
