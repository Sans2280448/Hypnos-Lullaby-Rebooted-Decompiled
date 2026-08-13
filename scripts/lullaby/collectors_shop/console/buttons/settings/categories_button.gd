extends SettingsButton

@export var settings_portraits: AnimatedSprite2D
@export var portrait_name: String = "gf"
@export var submenu: TabContainer
@export var submenu_index = 0
@export var backout_node: Button

@onready var default_focus: Control = submenu.get_child(submenu_index).default_focus

func _on_button_pressed():
	super._on_button_pressed()
	console.play_sound.emit("sfx_soulroom_select_alt")
	console.backout_focus = backout_node
	console.in_submenu = true
	submenu.current_tab = submenu_index
	if default_focus:
		default_focus.grab_focus()

func _on_focus_entered():
	super._on_focus_entered()
	settings_portraits.play(portrait_name)
