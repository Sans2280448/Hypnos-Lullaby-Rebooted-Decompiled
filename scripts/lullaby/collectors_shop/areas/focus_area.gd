class_name FocusArea3D extends TriggerArea3D

@export var shop: CollectorShop
@export var sequences: ShopSequences
@export var animation_name: StringName

var is_focused: bool

func trigger() -> void :
	if not can_interact:
		return
	sequences.animation_player.play(animation_name)
	sequences.animation_player.seek(0.0, true)



func register_trigger() -> void :
	if not can_interact:
		return
	super ()

	CollectorShop.current_area = self
