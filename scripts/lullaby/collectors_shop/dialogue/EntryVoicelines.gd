extends Node
class_name EntryVoicelines

@export var shop: CollectorShop

@export_group("Entry Groups")
@export var pokedhat_finale_group: String = "hatreturn"
@export var default_group: String = "joiningback"

@export_group("Generic Return Groups")
@export var generic_failed_group: String = "generic_failed_return"
@export var generic_passed_group: String = "generic_passed_return"

@export_group("Monochrome Groups")
@export var monochrome_failed_group: String = "monochrome_failed_return"
@export var monochrome_passed_group: String = "monochrome_passed_return"

@export_group("Safety Lullaby Groups")
@export var safety_failed_group: String = "safety_failed_return"
@export var safety_passed_group: String = "safety_passed_return"

@export_group("Chimera Groups")
@export var chimera_failed_group: String = "chimera_failed_return"
@export var chimera_passed_group: String = "chimera_passed_return"

@export_group("Flags")
@export var pokedhat_finale_flag: StringName = &"pokedhatfinale"

@export var monochrome_played_flag: StringName = &"playedmonochrome"
@export var monochrome_failed_seen_flag: StringName = &"monochrome_failed_seen"
@export var monochrome_passed_seen_flag: StringName = &"monochrome_passed_seen"

@export var safety_played_flag: StringName = &"playedsafety"
@export var safety_failed_seen_flag: StringName = &"safety_lullaby_failed_seen"
@export var safety_passed_seen_flag: StringName = &"safety_lullaby_passed_seen"

@export var chimera_played_flag: StringName = &"playedchimera"
@export var chimera_failed_seen_flag: StringName = &"chimera_failed_seen"
@export var chimera_passed_seen_flag: StringName = &"chimera_passed_seen"

func play_entry_voiceline() -> void :
	if shop == null or not SaveData.get_flag(&"intro_seen"):
		return

	if shop == null or (SaveData.get_flag(&"credits_scroll_seen") and not SaveData.get_flag("outro_seen")):
		return

	if SaveData.get_flag(pokedhat_finale_flag):
		shop.play_voiceline_group(pokedhat_finale_group, false)
		SaveData.set_flag(pokedhat_finale_flag, false)
		SaveData.save()
		return

	if _play_song_return(
		monochrome_played_flag, 
		&"monochrome", 
		monochrome_failed_group, 
		monochrome_passed_group, 
		monochrome_failed_seen_flag, 
		monochrome_passed_seen_flag
	):
		return

	if _play_song_return(
		safety_played_flag, 
		&"safety_lullaby", 
		safety_failed_group, 
		safety_passed_group, 
		safety_failed_seen_flag, 
		safety_passed_seen_flag, 
		true
	):
		return

	if _play_song_return(
		chimera_played_flag, 
		&"chimera", 
		chimera_failed_group, 
		chimera_passed_group, 
		chimera_failed_seen_flag, 
		chimera_passed_seen_flag
	):
		return

	if default_group != "":
		shop.play_voiceline_group(default_group, true)

func _play_song_return(
	played_flag: StringName, 
	song_name: StringName, 
	failed_group: String, 
	passed_group: String, 
	failed_seen_flag: StringName, 
	passed_seen_flag: StringName, 
	play_full_group: bool = false
) -> bool:
	if not SaveData.get_flag(played_flag):
		return false

	if SaveData.has_passed_song(song_name):
		_play_result_group(
			passed_group, 
			generic_passed_group, 
			passed_seen_flag, 
			play_full_group
		)
	else:
		_play_result_group(
			failed_group, 
			generic_failed_group, 
			failed_seen_flag
		)

	SaveData.set_flag(played_flag, false)
	SaveData.save()

	return true

func _play_result_group(
	specific_group: String, 
	generic_group: String, 
	seen_flag: StringName, 
	play_full_group: bool = false
) -> void :
	if SaveData.get_flag(seen_flag):
		if generic_group != "":
			shop.play_voiceline_group(generic_group, true)
		return

	if specific_group != "":
		if play_full_group:
			shop.play_full_voiceline_group(specific_group, true)
		else:
			shop.play_voiceline_group(specific_group, true)

	SaveData.set_flag(seen_flag, true)
