class_name LullabySongCheck
extends Node

@export var flag: String

func _ready() -> void :
	SaveData.set_flag(flag, true)
	SaveData.save()
