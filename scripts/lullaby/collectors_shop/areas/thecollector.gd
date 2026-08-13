extends TriggerArea3D

@export var shop: CollectorShop
@export var sequences: ShopSequences

func trigger() -> void :
	if not can_interact: return
	if not shop.voiceline_is_active:
		shop.play_voiceline_group("himself")
