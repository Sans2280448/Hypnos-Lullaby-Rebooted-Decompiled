extends SettingsButton

signal toggle_checkbox

@export var is_activated: bool
@export var property: StringName
@onready var checkbox = get_child(0)

func _ready() -> void :
	super._ready()
	is_activated = Settings.get(property)
	checkbox.position.x = size.x + 60
	checkbox.check.visible = is_activated

func _on_button_pressed():
	console.play_sound.emit("sfx_soulroom_select_alt")
	is_activated = not is_activated
	toggle_checkbox.emit()
	if is_activated:
		console.shop.play_voiceline_group("babyon", true)

	Settings.set(property, is_activated)
	Settings.apply_settings()
