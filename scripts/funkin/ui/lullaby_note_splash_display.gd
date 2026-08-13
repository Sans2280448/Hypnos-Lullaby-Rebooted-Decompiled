@tool
extends Control
class_name LullabyNoteSplashDisplay

@export var enabled: bool = true
@export var animation_player: AnimationPlayer
@export var splash_animation_name: StringName

var _note_handler: RubiconLevelNoteHandler:
	set(value):
		if _note_handler == value:
			return

		if _note_handler != null:
			if _note_handler._controller.note_changed.is_connected(note_changed):
				_note_handler._controller.note_changed.disconnect(note_changed)

		_note_handler = value

		if _note_handler != null:
			_note_handler._controller.connect(&"note_changed", note_changed)

func note_changed(result: RubiconLevelNoteHitResult, has_ending_row: bool) -> void :
	if result == null or animation_player == null:
		return

	if result.handler.get_unique_id() != _note_handler.get_unique_id():
		return

	if result.scoring_hit == result.Hit.HIT_COMPLETE and has_ending_row:
		return

	if result.scoring_rating == result.Judgment.JUDGMENT_PERFECT or result.scoring_rating == result.Judgment.JUDGMENT_GREAT:
		animation_player.play(splash_animation_name)
		animation_player.seek(0.0, true)

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_PARENTED:
			_note_handler = null

			var parent: Node = get_parent()
			if parent is RubiconLevelNoteHandler:
				_note_handler = parent
