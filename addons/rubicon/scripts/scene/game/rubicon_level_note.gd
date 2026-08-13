@tool
@abstract class_name RubiconLevelNote extends Control

var data_index: int = 0
var missed: bool = false

var handler: RubiconLevelNoteHandler:
	get:
		return _handler

var _handler: RubiconLevelNoteHandler

func initialize(handler: RubiconLevelNoteHandler, data_index: int) -> void :
	_handler = handler
	self.data_index = data_index

func was_hit() -> bool:
	var result: RubiconLevelNoteHitResult = get_hit_result()
	if result == null:
		return false

	return result.scoring_hit != RubiconLevelNoteHitResult.Hit.HIT_NONE

func was_missed() -> bool:
	var result: RubiconLevelNoteHitResult = get_hit_result()
	if result == null:
		return false

	return result.scoring_rating == RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS

func get_hit_result() -> RubiconLevelNoteHitResult:
	return _handler.results[data_index] if _handler != null else null

func _enter_tree() -> void :
	pass

func _exit_tree() -> void :
	missed = false

func _should_process() -> bool:
	return _handler != null and _handler._should_process()
