class_name LullabySongGrade extends RefCounted

enum Clear
{
	CLEAR_NONE = 0, 
	CLEAR_PASSED = 1, 
	CLEAR_FULL_COMBO = 2, 
	CLEAR_GREAT_FULL_COMBO = 3, 
	CLEAR_PERFECT_FULL_COMBO = 4
}

enum Rank
{
	RANK_F = 0, 
	RANK_D = 1, 
	RANK_C = 2, 
	RANK_B = 3, 
	RANK_A = 4, 
	RANK_S = 5, 
	RANK_SS = 6, 
	RANK_SSS = 7, 
	RANK_P = 8
}

var score: int = 0
var highest_combo: int = 0
var accuracy: float = 0.0
var misses: int = 0
var clear: Clear = Clear.CLEAR_NONE
var rank: Rank = Rank.RANK_F

func compare_to(compare: LullabySongGrade) -> int:
	if (
		rank == compare.rank and 
		clear == compare.clear and 
		score == compare.score and 
		highest_combo == compare.highest_combo and 
		is_equal_approx(accuracy, compare.accuracy) and 
		misses == compare.misses
	):
		return 0

	if rank > compare.rank or clear > compare.clear:
		return 1

	if score > compare.score:
		return 1

	if highest_combo > compare.highest_combo:
		return 1

	if accuracy > compare.accuracy:
		return 1

	if misses < compare.misses:
		return 1

	return -1
