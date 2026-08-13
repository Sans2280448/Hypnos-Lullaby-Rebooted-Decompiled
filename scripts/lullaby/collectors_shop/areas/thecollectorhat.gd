extends TriggerArea3D

@export var shop: CollectorShop
@export var sequences: ShopSequences

var interacted: int = 0

func trigger() -> void :
	if not can_interact: return

	if shop.voiceline_is_active:
		return

	if interacted >= 3:
		SaveData.set_flag("pokedhatfinale", true)
		SaveData.save()
		get_tree().quit()
	else:
		shop.play_voiceline_group("hat", false)
		interacted = interacted + 1
