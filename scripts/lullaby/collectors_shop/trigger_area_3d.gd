@abstract
extends Area3D
class_name TriggerArea3D

signal area_triggered
@export var can_interact: bool = true
@abstract func trigger() -> void 

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_READY:
			area_triggered.connect(register_trigger)

func register_trigger() -> void :
	CollectorShop.last_trigger = self
