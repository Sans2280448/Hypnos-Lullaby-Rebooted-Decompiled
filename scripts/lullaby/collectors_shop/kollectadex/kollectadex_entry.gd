@tool
class_name KollectadexEntry
extends Control

signal change_focus(char)

@export_placeholder("Placeholder") var character_name: String = "":
	set(value):
		character_name = value
		if reference_name_label != null:
			reference_name_label.text = character_name

@export var character_image: Texture2D
@export_placeholder("Placeholder") var character_subtitle: String = ""
@export_multiline var character_desc: String = ""


@export var unlock_song: StringName = "safety_lullaby"

@export var seen_on: String = "Safety Lullaby"




@export_group("Focus Indicator", "focus_texture_")
@export var focus_texture_selected: Texture2D
@export var focus_texture_unselected: Texture2D

@export_group("References", "reference_")
@export var reference_focus_indicator: TextureRect
@export var reference_number_label: Label
@export var reference_name_label: Label

var unlocked: bool = false

@export var index: int:
	set(value):
		index = value
		if reference_number_label != null:
			reference_number_label.text = str(index).pad_zeros(3)

func _ready() -> void :
	if Engine.is_editor_hint():
		return

	unlocked = SaveData.has_passed_song(unlock_song)

	if unlocked:
		return

	reference_name_label.modulate = Color(0.5, 0.5, 0.5)
	reference_number_label.modulate = reference_name_label.modulate
	character_name = "???"
	character_subtitle = "???"
	character_desc = "???"

func _on_focus_entered() -> void :
	change_focus.emit(self);
	reference_focus_indicator.texture = focus_texture_selected

func _on_focus_exited() -> void :
	reference_focus_indicator.texture = focus_texture_unselected
