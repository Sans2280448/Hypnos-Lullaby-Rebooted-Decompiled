extends Control

const FLAGS_FOR_CREDITS: Array[StringName] = [&"safety_lullaby_beaten", &"monochrome_beaten", &"chimera_beaten"]

@export var disable_when_active: Array[Node]
@export var song_grader: LullabySongGrader

@export var target_timeline: AnimationPlayer

@export var results_label: Label
@export var animation_player: AnimationPlayer

@export var soultoken_count: Label

@export var song_name: String = "safety_lullaby"

var active: bool = false


func _ready() -> void :
	if target_timeline:
		target_timeline.animation_finished.connect(_on_song_finished)

	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

	if soultoken_count:
		soultoken_count.text = str(SaveData.tokens)


func _unhandled_input(event: InputEvent) -> void :
	if not active or event.is_echo() or not event.is_pressed():
		return

	get_viewport().set_input_as_handled()

	if event.is_action(&"ui_accept"):
		active = false

		if SaveData.just_got_token:
			animation_player.play(&"show_tokens")
		else:
			animation_player.play(&"close")


func _on_animation_finished(anim_name: StringName) -> void :
	match anim_name:
		&"show":
			LullabyGameoverModule.has_died = false
			active = true
		&"show_tokens", &"close":

			var passed_songs: int = 0
			for flag in FLAGS_FOR_CREDITS:
				if SaveData.get_flag(flag):
					passed_songs += 1

			if passed_songs >= 3 and not SaveData.get_flag(&"credits_scroll_seen"):
				SceneChanger.change_to("uid://c56x7ch1lypk3", &"hypno", false)
			else:
				SceneChanger.change_to("uid://bqkjiwokrcvo", &"hypno", true)


func _on_song_finished(_anim_name: StringName) -> void :
	for node in disable_when_active:
		node.process_mode = Node.PROCESS_MODE_DISABLED

		if "active" in node:
			node.active = false

	if not song_grader:
		return

	var grade: LullabySongGrade = song_grader.get_grade()
	var new_grade: bool = true

	if SaveData.song_grades.has(song_name):
		var prev_grade: LullabySongGrade = SaveData.song_grades[song_name]
		if grade.compare_to(prev_grade) != 1:
			new_grade = false

	if new_grade:
		SaveData.song_grades[song_name] = grade

	var beaten_name: = &"%s_beaten" % song_name
	if ( not SaveData.get_flag(beaten_name)) and ( not Settings.lullaby_baby_mode):
		SaveData.tokens += 1
		SaveData.set_flag(beaten_name, true)
		SaveData.just_got_token = true

	SaveData.save()

	if results_label:
		results_label.text = "Score: %d\nHighest Combo: %d\nMisses: %d\nAccuracy: %.2f%%\nRank: %s\nClear: %s" % [
			grade.score, 
			grade.highest_combo, 
			grade.misses, 
			grade.accuracy, 
			LullabySongGrader.get_rank_as_string(grade.rank), 
			LullabySongGrader.get_clear_as_string(grade.clear)
		]

		if new_grade:
			results_label.text += "\n\nNEW GRADE!!!"

	if animation_player:
		animation_player.play(&"show")


func add_soultoken() -> void :
	if soultoken_count:
		soultoken_count.text = str(SaveData.tokens)
