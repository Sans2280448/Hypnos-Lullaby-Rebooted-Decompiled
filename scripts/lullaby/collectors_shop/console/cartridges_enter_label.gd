extends RichTextLabel

@export var collector_shop: CollectorShop
@export var animation_player: AnimationPlayer
@export var console: Console


func _ready() -> void :
	update_cartridge(SaveData.cartridge_selected)
	SaveData.new_cartridge_selected.connect(update_cartridge)


func update_cartridge(cart: StringName) -> void :
	animation_player.play(cart)


func _gui_input(event: InputEvent) -> void :
	if event.is_echo() or not event.is_pressed():
		return

	if console.booting:
		return

	if event.is_action(&"ui_accept"):
		var scene_path: String
		var is_chimera: bool = false
		match SaveData.cartridge_selected:
			&"safety_lullaby":
				scene_path = "uid://d1qubpqxts4w3"
			&"monochrome":
				scene_path = "uid://dfflo57l50r1f"
			&"chimera":
				if Settings.lullaby_baby_mode:
					if collector_shop: collector_shop.play_voiceline_entry(collector_shop.get_voiceline_group("baby_chim").voicelines[0], false)
					return
				scene_path = "uid://k26b7med2dat"
				is_chimera = true

		focus_mode = Control.FOCUS_NONE
		console.focused = false
		console.play_sound.emit("sfx_soulroom_select")
		collector_shop.sequence_controller.animation_player.play("sequence_consoletosong")
		await collector_shop.sequence_controller.animation_player.animation_finished

		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN

		SceneChanger.change_to(scene_path, &"hypno", is_chimera)
