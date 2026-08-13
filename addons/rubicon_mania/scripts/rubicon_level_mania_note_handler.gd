@tool
class_name RubiconLevelManiaNoteHandler extends RubiconLevelNoteHandler

enum LaneState{
	LANE_STATE_NEUTRAL = 0, 
	LANE_STATE_PUSH = 1, 
	LANE_STATE_HIT = 2
}

@export var global_direction: float = -1.571
@export var allow_misplays: bool = true

@export_group("Lane", "lane_")
@export var lane_id: int = 0
@export var lane_state: LaneState

signal misplayed(lane_id: int)

func _init() -> void :
	settings = load("res://addons/rubicon_mania/resources/default_settings.tres")

func hit_note(index: int, time_when_hit: float, hit_type: RubiconLevelNoteHitResult.Hit) -> void :
	super (index, time_when_hit, hit_type)

	if results[index].scoring_rating < RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS and results[index].scoring_rating != RubiconLevelNoteHitResult.Judgment.JUDGMENT_NONE:
		lane_state = LaneState.LANE_STATE_HIT

	if hit_type == RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
		results[index].scoring_value = 0.25
		return

	match results[index].scoring_rating:
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT:
			results[index].scoring_value = 1.0
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT:
			results[index].scoring_value = 0.9375
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD:
			results[index].scoring_value = 0.625
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY:
			results[index].scoring_value = 0.3125
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD:
			results[index].scoring_value = 0.9375
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS:
			results[index].scoring_value = 0.15625

func sort_graphic(data_index: int) -> void :
	var graphic: RubiconLevelNote = graphics[data_index]


	if data_index > 0 and data_index < data.size() and graphics[data_index - 1] != null:
		move_child(graphic, graphics[data_index - 1].get_index() + 1)
		return

	if data_index + 1 < data.size() and graphics[data_index + 1] != null:
		move_child(graphic, graphics[data_index + 1].get_index())
		return

	var target_index: int = -1
	for i in graphics.size():
		var current: RubiconLevelNote = graphics[i]
		if current != null:
			if i < data_index:
				target_index = current.get_index() + 1
			else:
				target_index = current.get_index()

			break

	move_child(graphic, target_index)

func get_mode_id() -> StringName:
	return "mania"

func get_unique_id() -> StringName:
	return "mania_lane%s" % lane_id

func _process(delta: float) -> void :
	super (delta)
	if not _should_process():
		return

	if get_controller().should_autoplay() and note_hit_index > 0 and lane_state == LaneState.LANE_STATE_HIT and (results[note_hit_index - 1] == null or results[note_hit_index - 1].scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_COMPLETE):
		lane_state = LaneState.LANE_STATE_NEUTRAL

func _press(event: InputEvent) -> void :
	var controller: RubiconLevelNoteController = get_controller()
	if note_hit_index >= data.size():
		lane_state = LaneState.LANE_STATE_PUSH

		just_pressed.emit()
		controller.handler_just_pressed.emit(get_unique_id())
		return

	var precise_time: float = controller.get_level_clock().get_time_precise() + controller.offset_input
	var hit_time: float = data[note_hit_index].get_millisecond_start_position() - precise_time
	while data[note_hit_index].get_millisecond_start_position() <= - settings.judgment_window_bad:
		hit_note(note_hit_index, precise_time, RubiconLevelNoteHitResult.Hit.HIT_COMPLETE)
		note_hit_index += 1
		controller.update_performance()

		hit_time = data[note_hit_index].get_millisecond_start_position() - precise_time

	if absf(hit_time) <= settings.judgment_window_bad:
		if data[note_hit_index].ending_row != null:
			hit_note(note_hit_index, precise_time, RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE)
			controller.update_performance()
		else:
			hit_note(note_hit_index, precise_time, RubiconLevelNoteHitResult.Hit.HIT_COMPLETE)
			note_hit_index += 1
			controller.update_performance()

	else:
		lane_state = LaneState.LANE_STATE_PUSH

		if not allow_misplays:
			if not break_combo_indexes.has(note_hit_index - 1):
				break_combo_indexes.append(note_hit_index - 1)

			misplayed.emit(lane_id)

	just_pressed.emit()
	controller.handler_just_pressed.emit(get_unique_id())

func _release(event: InputEvent) -> void :
	var controller: RubiconLevelNoteController = get_controller()
	if note_hit_index < data.size() and results[note_hit_index] != null and results[note_hit_index].scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
		hit_note(note_hit_index, controller.get_level_clock().get_time_precise() + controller.offset_input, RubiconLevelNoteHitResult.Hit.HIT_COMPLETE)
		note_hit_index += 1
		controller.update_performance()

	if lane_state != LaneState.LANE_STATE_NEUTRAL:
		lane_state = LaneState.LANE_STATE_NEUTRAL

	just_pressed.emit()
	controller.handler_just_released.emit(get_unique_id())

func _autoplay_process(millisecond_position: float) -> void :
	while note_hit_index < data.size() and data[note_hit_index].get_millisecond_start_position() - millisecond_position <= 0:

		if data[note_hit_index].ending_row != null:
			if results[note_hit_index] == null or results[note_hit_index].scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_NONE:
				hit_note(note_hit_index, data[note_hit_index].get_millisecond_start_position(), RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE)
				get_controller().update_performance()

			break

		hit_note(note_hit_index, data[note_hit_index].get_millisecond_end_position(), RubiconLevelNoteHitResult.Hit.HIT_COMPLETE)
		note_hit_index += 1

		get_controller().update_performance()

func _property_get_revert(property: StringName) -> Variant:
	if property == "settings" and ResourceLoader.exists("res://addons/rubicon_mania/resources/default_settings.tres"):
		return load("res://addons/rubicon_mania/resources/default_settings.tres")

	return super (property)
