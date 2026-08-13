extends TriggerArea3D

@export var shop: CollectorShop
@export var sequences: ShopSequences
@export var sign_animation: AnimationPlayer

var focused: bool = false

func trigger() -> void :
	if not can_interact: return

	if not SaveData.get_flag("intro_sign_seen"):
		sequences.animation_player.play("sequence_sign_intro")
		SaveData.set_flag("intro_sign_seen", true)
		SaveData.save()
		focused = true
	else:
		sequences.animation_player.play("sequence_sign", -1, 1.25)
		focused = true

func _input(event: InputEvent) -> void :
	if event.is_echo() or not event.is_pressed():
		return

	if event.is_action(&"ui_cancel"):
		if shop.state == shop.ShopStates.FOCUSED and focused:
			focused = false

			if sign_animation.is_animation_active():
				var sign_anim_time: float = sign_animation.current_animation_position
				if sign_anim_time > 0.0:
					sequences.animation_player.stop(true)
					sign_animation.play_section_backwards(&"Intro", 0.0, sign_anim_time)
					return

			sign_animation.play_backwards(&"Intro")
