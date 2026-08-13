class_name LullabyFirstBootSettings extends Node

@export var focus_first: Control
@export var preset_description: Label

func _ready() -> void :
	_on_preset_changed(3)
	focus_first.grab_focus()

func _on_preset_changed(index: int) -> void :
	var text: String = "Whatever you want."
	match index:
		1:
			text = "Bottom-of-the-barrel visuals [Post-proccesing off, zero antialiasing]"
		2:
			text = "For the average computer [Post-processing low, basic antilaliasing]"
		3:
			text = "The intended experience. [Post-processing and antialiasing at its max]"

	preset_description.text = text

func open_settings() -> void :
	Debugger.settings.open()

func apply_and_continue() -> void :
	SaveData.set_flag(&"first_boot_seen", true)

	Settings.apply_settings()
	Settings.save()

	get_tree().change_scene_to_file("res://rooms/scn_boot.tscn")
