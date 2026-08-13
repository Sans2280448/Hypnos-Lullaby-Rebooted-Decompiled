@tool
class_name RubiconLevelNoteHitResult extends RefCounted

























































enum Judgment{
	JUDGMENT_NONE = 1 << 0, 
	JUDGMENT_PERFECT = 1 << 1, 
	JUDGMENT_GREAT = 1 << 2, 
	JUDGMENT_GOOD = 1 << 3, 
	JUDGMENT_OKAY = 1 << 4, 
	JUDGMENT_BAD = 1 << 5, 
	JUDGMENT_MISS = 1 << 6
}

enum Hit{

	HIT_NONE = 0, 

	HIT_INCOMPLETE = 1, 

	HIT_COMPLETE = 2
}

enum ModifierFlags
{
	MODIFIER_FLAG_NONE = 1 << 0, 
	MODIFIER_FLAG_SPLASH = 1 << 1, 
	MODIFIER_FLAG_ANIMATION = 1 << 2, 
	MODIFIER_FLAG_VOCALS = 1 << 3
}

@export var data_index: int = 0
@export var animation: StringName
@export var flags: ModifierFlags = ModifierFlags.MODIFIER_FLAG_NONE

@export_group("Scoring", "scoring_")
@export_range(0.0, 1.0) var scoring_value: float = 1.0
@export var scoring_health_delta: int = 0
@export var scoring_rating: Judgment = Judgment.JUDGMENT_NONE
@export var scoring_hit: Hit = Hit.HIT_NONE

@export_group("Time", "time_")
@export var time_distance: float
@export var time_when_hit: float

var handler: RubiconLevelNoteHandler

func _init(assigned_handler: RubiconLevelNoteHandler) -> void :
	handler = assigned_handler

func reset(to_state: Hit) -> void :
	if to_state == Hit.HIT_COMPLETE or (to_state == Hit.HIT_INCOMPLETE and scoring_hit == Hit.HIT_INCOMPLETE):
		return

	match to_state:
		Hit.HIT_NONE:
			flags = ModifierFlags.MODIFIER_FLAG_NONE
			scoring_health_delta = 0
			scoring_value = 0.0
			scoring_rating = Judgment.JUDGMENT_NONE
			scoring_hit = to_state
		Hit.HIT_INCOMPLETE:
			handler.hit_note(data_index, handler.data[data_index].get_millisecond_start_position(), Hit.HIT_INCOMPLETE)

func get_note_data() -> RubiChartNote:
	return handler.data[data_index]

func get_accuracy_value() -> float:
	match scoring_rating:
		Judgment.JUDGMENT_PERFECT:
			return 1.0
		Judgment.JUDGMENT_GREAT:
			return 0.95
		Judgment.JUDGMENT_GOOD:
			return 0.65
		Judgment.JUDGMENT_OKAY:
			return 0.3
		Judgment.JUDGMENT_BAD:
			return 0.15
		_, Judgment.JUDGMENT_NONE, Judgment.JUDGMENT_MISS:
			return 0.0

static func compare_results_by_time_hit(x: RubiconLevelNoteHitResult, y: RubiconLevelNoteHitResult) -> bool:
	return x.time_when_hit < y.time_when_hit
