extends LullabySongGrader

@export var heartbeat_controller: HeartbeatController

func get_grade() -> LullabySongGrade:
	var grade: LullabySongGrade = super.get_grade()

	var beats_successful: int = heartbeat_controller.beats_successful
	var total_beats: int = heartbeat_controller.total_beats


	var heartbeat_score: int = floori(50000 * (beats_successful / float(total_beats))) if beats_successful < total_beats else 50000
	grade.score += heartbeat_score




	grade.accuracy = (grade.accuracy * 0.75) + ((beats_successful / float(total_beats)) * 0.25 * 100.0)
	grade.misses += total_beats - beats_successful

	return grade

func get_clear() -> LullabySongGrade.Clear:
	var clear: LullabySongGrade.Clear = super.get_clear()
	if heartbeat_controller.beats_successful >= heartbeat_controller.total_beats:
		return clear

	return LullabySongGrade.Clear.CLEAR_PASSED

func get_rank() -> LullabySongGrade.Rank:
	if not _controller:
		return LullabySongGrade.Rank.RANK_F

	var beats_successful: int = heartbeat_controller.beats_successful
	var total_beats: int = heartbeat_controller.total_beats

	var note_score: int = _controller.performance_score_value
	var heart_score: int = floori((beats_successful / float(total_beats)) * 50000) if beats_successful < total_beats else 50000
	var score: int = note_score + heart_score
	var max_score: int = 100000
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
