class_name ShopConsolePower
extends TriggerArea3D

@export var hint: Control
@export var console_area: SubmenuArea
@export var bag_focus: FocusArea3D
@export var animation: AnimationPlayer

static var on: bool = false:
	set(v):
		if on != v:
			on = v
			SaveData.set_flag(&"console_on", on)
			SaveData.save()

@export var shop: CollectorShop
@export var console: Console
@export var indicator: Node3D
@export var tv_light: OmniLight3D

@onready var click_sound: AudioStreamPlayer3D = $ClickSound

var modulate_target: Color


func _ready() -> void :
	on = SaveData.get_flag(&"console_on")

	animation.play("button_on") if on else animation.play("button_off")

	bag_focus.can_interact = SaveData.get_flag(&"console_boot_seen")

	if on:
		console.modulate = Color.WHITE
		tv_light.light_energy = 0
	else:
		console.modulate = Color.BLACK
		tv_light.light_energy = 0.241

	indicator.visible = on
	_update_on()


func _process(delta: float) -> void :
	console.modulate = console.modulate.lerp(modulate_target, delta * 16.0)


func trigger() -> void :
	if not can_interact:
		return

	click_sound.play()
	on = not on
	_update_on()

	if on:
		boot_console()


func boot_console() -> void :
	if not SaveData.get_flag(&"console_area_seen"):
		SaveData.set_flag(&"console_area_seen", true)
		SaveData.save()

	console_area.trigger()
	console_area.register_trigger()
	console.modulate = Color.WHITE
	modulate_target = Color.WHITE
	on = true
	_update_on()

	shop.state = CollectorShop.ShopStates.BUSY
	Console.boot_enabled = true
	console.booting = true
	console.boot(true)
	console.startup_sound.volume_linear = 1.0
	console.other_sounds.volume_linear = 1.0

	await console.boot_finished

	if not SaveData.get_flag(&"console_boot_seen"):
		if is_instance_valid(hint):
			var hint_tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			hint_tween.tween_property(hint, "modulate:a", 0.65, 0.5)
			hint_tween.tween_property(hint, "modulate:a", 0, 1.0).set_delay(2.5)

		bag_focus.can_interact = true
		SaveData.set_flag(&"console_boot_seen", true)
		SaveData.save()


func _update_on() -> void :
	animation.play("button_on") if on else animation.play("button_off")
	if on:
		modulate_target = Color.WHITE
		tv_light.light_energy = 0.241
	else:
		modulate_target = Color.BLACK
		tv_light.light_energy = 0.0

	indicator.visible = on

	if console.music:
		console.music.playing = on
