class_name LullabySongGrader extends Node

var _controller: RubiconLevelNoteController

func get_grade() -> LullabySongGrade:
	var grade: LullabySongGrade = LullabySongGrade.new()
	grade.score = _controller.performance_score_value
	grade.highest_combo = _controller.performance_combo_highest
	grade.accuracy = _controller.performance_accuracy_percent
	grade.misses = _controller.performance_hits_miss
	grade.clear = get_clear()
	grade.rank = get_rank()

	return grade

func get_clear() -> LullabySongGrade.Clear:
	if not _controller:
		return LullabySongGrade.Clear.CLEAR_NONE

	var greats: int = _controller.performance_hits_great
	var goods: int = _controller.performance_hits_good
	var okays: int = _controller.performance_hits_okay
	var bads: int = _controller.performance_hits_bad
	var misses: int = _controller.performance_hits_miss
	if misses + bads + okays + goods + greats == 0:
		return LullabySongGrade.Clear.CLEAR_PERFECT_FULL_COMBO
	elif misses + bads + okays + goods == 0:
		return LullabySongGrade.Clear.CLEAR_GREAT_FULL_COMBO
	elif misses + bads + okays == 0:
		return LullabySongGrade.Clear.CLEAR_FULL_COMBO

	return LullabySongGrade.Clear.CLEAR_PASSED

func get_rank() -> LullabySongGrade.Rank:
	if not _controller:
		return LullabySongGrade.Rank.RANK_F

	var score: int = _controller.performance_score_value
	var max_score: int = _controller.performance_score_max
	if score >= max_score:
		return LullabySongGrade.Rank.RANK_P
	elif score >= max_score * 0.975:
		return LullabySongGrade.Rank.RANK_SSS
	elif score >= max_score * 0.95:
		return LullabySongGrade.Rank.RANK_SS
	elif score >= max_score * 0.9:
		return LullabySongGrade.Rank.RANK_S
	elif score >= max_score * 0.8:
		return LullabySongGrade.Rank.RANK_A
	elif score >= max_score * 0.7:
		return LullabySongGrade.Rank.RANK_B
	elif score >= max_score * 0.6:
		return LullabySongGrade.Rank.RANK_C

	return LullabySongGrade.Rank.RANK_D

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_PARENTED:
			_controller = null
			var parent: Node = get_parent()
			if parent is RubiconLevelNoteController:
				_controller = parent

static func get_clear_as_string(clear: LullabySongGrade.Clear) -> String:
	match clear:
		LullabySongGrade.Clear.CLEAR_NONE:
			return "Never Played"
		LullabySongGrade.Clear.CLEAR_PASSED:
			return "Passed"
		LullabySongGrade.Clear.CLEAR_FULL_COMBO:
			return "FC"
		LullabySongGrade.Clear.CLEAR_GREAT_FULL_COMBO:
			return "GFC"
		LullabySongGrade.Clear.CLEAR_PERFECT_FULL_COMBO:
			return "PFC"
		_:
			return "anniebuue speaking, how did you even GET this"

static func get_rank_as_string(rank: LullabySongGrade.Rank) -> String:
	match rank:
		LullabySongGrade.Rank.RANK_P:
			return "P"
		LullabySongGrade.Rank.RANK_SSS:
			return "SSS"
		LullabySongGrade.Rank.RANK_SS:
			return "SS"
		LullabySongGrade.Rank.RANK_S:
			return "S"
		LullabySongGrade.Rank.RANK_A:
			return "A"
		LullabySongGrade.Rank.RANK_B:
			return "B"
		LullabySongGrade.Rank.RANK_C:
			return "C"
		LullabySongGrade.Rank.RANK_D:
			return "D"
		LullabySongGrade.Rank.RANK_F:
			return "F"
		_:
			return "anniebuue speaking, theres NO way you got NO rank"
