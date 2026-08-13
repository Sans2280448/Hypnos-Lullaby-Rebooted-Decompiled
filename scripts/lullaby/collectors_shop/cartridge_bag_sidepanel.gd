class_name CartridgeBagSidepanel
extends Control


signal mode_selected(mode: String)

@export var tabs: TabContainer
@export var song_name: Label
@export var song_stats: Label


func _ready() -> void :
	reset_state()


func reset_state() -> void :
	tabs.current_tab = 0


func update_song(song: StringName, display_name: String) -> void :
	song_name.text = display_name

	if song.is_empty():
		song_stats.text = "Score:\n???\n\nAccuracy:\n???"
		return
	elif not SaveData.song_grades.has(song):
		song_stats.text = "Score:\nN/A\n\nAccuracy:\nN/A"
		return

	var grade: = SaveData.song_grades[song]
	song_stats.text = "Score:\n%d\n\nAccuracy:\n%.2f%%" % [
		grade.score, 
		grade.accuracy, 
	]


func _select_mode(mode: String) -> void :
	mode_selected.emit(mode)
	tabs.current_tab = 1
