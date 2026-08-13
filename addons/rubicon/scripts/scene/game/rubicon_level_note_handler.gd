@tool
@abstract class_name RubiconLevelNoteHandler extends Control

@export var settings: RubiconLevelNoteSettings

@export_group("Spawning", "spawning_")
@export var spawning_bound_maximum: float = 2000.0
@export var spawning_bound_minimum: float = -1000.0

var data: Array[RubiChartNote]
var graphics: Array[RubiconLevelNote]
var results: Array[RubiconLevelNoteHitResult]


var break_combo_indexes: Array[int] = []

var note_spawn_start: int = 0
var note_spawn_end: int = 0
var note_hit_index: int = 0
var last_hit_note_index: int = 0

var pressed: bool = false

var _controller: RubiconLevelNoteController
var _note_pool: Dictionary[StringName, Array]

func get_controller() -> RubiconLevelNoteController:
	return _controller

@abstract func get_mode_id() -> StringName
@abstract func get_unique_id() -> StringName

@abstract func sort_graphic(data_index: int) -> void 

@abstract func _press(event: InputEvent) -> void 
@abstract func _release(event: InputEvent) -> void 
@abstract func _autoplay_process(millisecond_position: float) -> void 

signal just_pressed
signal just_released

func update_notes() -> void :
	if _controller == null:
		return

	if _controller.chart == null:
		return

	note_spawn_start = 0
	note_spawn_end = 0
	note_hit_index = 0
	last_hit_note_index = 0

	for i in data.size():
		if graphics[i] == null:
			continue

		despawn_note(i)

	data = get_controller().chart.get_notes_of_id(get_unique_id())

	graphics.clear()
	graphics.resize(data.size())

	results.clear()
	results.resize(data.size())

func spawn_note(index: int) -> void :
	var note_type: StringName = data[index].type
	var define_key: StringName = "%s_%s" % [note_type, get_mode_id()] if not note_type.is_empty() else get_mode_id()
	if not _note_pool.has(define_key):
		_note_pool[define_key] = Array()

	var graphic: RubiconLevelNote = _note_pool[define_key].pop_back()
	if graphic == null:
		var skin: RubiconLevelNoteMetadata = get_controller().get_note_database()[define_key]
		var packed: PackedScene = skin.scene

		graphic = packed.instantiate()

	graphic.initialize(self, index)

	graphic.name = "Note %s" % index
	graphics[index] = graphic

	add_child(graphic)





	sort_graphic(index)

func despawn_note(index: int) -> void :
	var note_type: StringName = data[index].type
	var graphic: RubiconLevelNote = graphics[index]

	remove_child(graphic)

	var define_key: StringName = "%s_%s" % [note_type, get_mode_id()] if not note_type.is_empty() else get_mode_id()
	_note_pool[define_key].append(graphic)



	graphics[index] = null

func hit_note(index: int, time_when_hit: float, hit_type: RubiconLevelNoteHitResult.Hit) -> void :
	var result: RubiconLevelNoteHitResult
	if results[index] != null:
		result = results[index]
	else:
		result = RubiconLevelNoteHitResult.new(self)

	result.data_index = index
	result.scoring_hit = hit_type
	result.time_when_hit = time_when_hit

	var is_start: bool = (hit_type == RubiconLevelNoteHitResult.Hit.HIT_COMPLETE and data[index].ending_row == null) or (hit_type == RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE and data[index].ending_row != null)
	var millisecond_position: float = data[index].get_millisecond_start_position() if is_start else data[index].get_millisecond_end_position()
	result.time_distance = time_when_hit - millisecond_position

	var ratings: Array[RubiconLevelNoteHitResult.Judgment]
	var hit_windows: Array[float]
	if settings.judgment_enabled & RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT == RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT:
		ratings.append(RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT)
		hit_windows.append(settings.judgment_window_perfect)
	if settings.judgment_enabled & RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT == RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT:
		ratings.append(RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT)
		hit_windows.append(settings.judgment_window_great)
	if settings.judgment_enabled & RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD == RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD:
		ratings.append(RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD)
		hit_windows.append(settings.judgment_window_good)
	if settings.judgment_enabled & RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY == RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY:
		ratings.append(RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY)
		hit_windows.append(settings.judgment_window_okay)
	if settings.judgment_enabled & RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD == RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD:
		ratings.append(RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD)
		hit_windows.append(settings.judgment_window_bad)

	var rating: RubiconLevelNoteHitResult.Judgment = RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS
	for i in hit_windows.size():
		if absf(result.time_distance) <= hit_windows[i]:
			rating = ratings[i]
			break

	if is_start or rating > result.scoring_rating:
		result.scoring_rating = rating

	var controller: RubiconLevelNoteController = get_controller()
	var has_ending_row: bool = data[index].ending_row != null

	last_hit_note_index = index
	results[index] = result

	var note_type: StringName = data[index].type
	var define_key: StringName = "%s_%s" % [note_type, get_mode_id()] if not note_type.is_empty() else get_mode_id()
	controller.get_note_database()[define_key].note_hit(result)

	if controller.should_autoplay():
		pressed = is_start
		if pressed:
			just_pressed.emit()
			get_controller().handler_just_pressed.emit(get_unique_id())
		else:
			just_released.emit()
			get_controller().handler_just_released.emit(get_unique_id())

	controller.note_changed.emit(result, has_ending_row)

func _exit_tree() -> void :
	for pool: Array in _note_pool.values():
		for value: Variant in pool:
			if value is Node:
				value.free()

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_PARENTED:
			if _controller != null:
				_controller.note_handlers.erase(get_unique_id())

			_controller = null

			var parent: Node = get_parent()
			if parent is RubiconLevelNoteController:
				_controller = parent
				_controller.note_handlers[get_unique_id()] = self
				update_notes()

		NOTIFICATION_EDITOR_PRE_SAVE:
			if not Engine.is_editor_hint():
				return




		NOTIFICATION_EDITOR_POST_SAVE:
			if not Engine.is_editor_hint():
				return





func _should_process() -> bool:
	return not data.is_empty() and settings != null and _controller != null and _controller.get_level_clock() != null

func _process(delta: float) -> void :
	if not _should_process():
		return

	var millisecond_position: float = get_controller().get_level_clock().time_milliseconds


	while note_spawn_start < data.size() and data[note_spawn_start].get_millisecond_end_position() - millisecond_position < spawning_bound_minimum:
		note_spawn_start += 1

	while note_spawn_end < data.size() and data[note_spawn_end].get_millisecond_start_position() - millisecond_position <= spawning_bound_maximum:
		note_spawn_end += 1


	var autoplay: bool = get_controller().should_autoplay() and not get_controller().disable_inputs
	if autoplay:
		while _has_passed_last_note(millisecond_position):
			_roll_hit_back()

		if note_hit_index < data.size():
			if _has_passed_current_long_note(millisecond_position) and results[note_hit_index] != null:
				results[note_hit_index].reset(RubiconLevelNoteHitResult.Hit.HIT_NONE)
			elif _is_inside_of_incomplete_note(millisecond_position):
				_reset_to_incomplete_note()

	while note_spawn_start > 0 and data[note_spawn_start - 1].get_millisecond_end_position() - millisecond_position > spawning_bound_minimum:
		note_spawn_start -= 1

	while note_spawn_end - 1 > 0 and data[note_spawn_end - 1].get_millisecond_start_position() - millisecond_position > spawning_bound_maximum:
		note_spawn_end -= 1

	for i in range(0, note_spawn_start):
		if graphics[i] != null:
			despawn_note(i)

	for i in range(note_spawn_end, data.size()):
		if graphics[i] != null:
			despawn_note(i)

	for i in range(note_spawn_start, note_spawn_end):
		if graphics[i] == null:
			spawn_note(i)

	if note_hit_index >= data.size():
		return

	if autoplay:
		_autoplay_process(millisecond_position)

	var should_complete: bool = note_hit_index < data.size() and results[note_hit_index] != null and results[note_hit_index].scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE and data[note_hit_index].get_millisecond_end_position() - millisecond_position <= 0.0
	if should_complete:
		hit_note(note_hit_index, data[note_hit_index].get_millisecond_end_position(), RubiconLevelNoteHitResult.Hit.HIT_COMPLETE)
		note_hit_index += 1

		get_controller().update_performance()

	while not autoplay and note_hit_index < data.size() and data[note_hit_index].get_millisecond_start_position() - millisecond_position < - settings.judgment_window_bad and (results[note_hit_index] == null or results[note_hit_index].scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_NONE):

		hit_note(note_hit_index, data[note_hit_index].get_millisecond_start_position() + settings.judgment_window_bad + 1000, RubiconLevelNoteHitResult.Hit.HIT_COMPLETE)
		note_hit_index += 1

		get_controller().update_performance()

func _has_passed_last_note(millisecond_position: float) -> bool:
	var has_last_note: bool = note_hit_index > 0
	if not has_last_note:
		return false

	var passed_end_of_last_single_note: bool = data[note_hit_index - 1].ending_row == null and data[note_hit_index - 1].get_millisecond_end_position() - millisecond_position >= settings.judgment_window_bad
	var passed_end_of_last_long_note: bool = data[note_hit_index - 1].ending_row != null and data[note_hit_index - 1].get_millisecond_end_position() - millisecond_position >= 0.0
	return passed_end_of_last_single_note or passed_end_of_last_long_note

func _has_passed_current_long_note(millisecond_position: float) -> bool:
	var passed_start_of_current_long_note: bool = data[note_hit_index].ending_row != null and data[note_hit_index].get_millisecond_start_position() - millisecond_position >= settings.judgment_window_bad
	return passed_start_of_current_long_note

func _is_inside_of_incomplete_note(millisecond_position: float) -> bool:
	var passed_start_of_current_long_note: bool = data[note_hit_index].ending_row != null and data[note_hit_index].get_millisecond_start_position() - millisecond_position >= settings.judgment_window_bad
	return results[note_hit_index] != null and results[note_hit_index].scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE

func _roll_hit_back() -> void :
	note_hit_index -= 1
	last_hit_note_index -= 1

	break_combo_indexes.erase(note_hit_index)

	var controller: RubiconLevelNoteController = get_controller()
	results[note_hit_index].reset(RubiconLevelNoteHitResult.Hit.HIT_NONE)

	controller.update_performance()
	controller.note_changed.emit(results[note_hit_index], data[note_hit_index].ending_row != null)

func _reset_to_incomplete_note() -> void :
	if results[note_hit_index] == null or results[note_hit_index].scoring_hit != RubiconLevelNoteHitResult.Hit.HIT_COMPLETE:
		return

	results[note_hit_index].reset(RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE)

func _property_can_revert(property: StringName) -> bool:
	if property == "settings":
		return true

	return false

func _property_get_revert(property: StringName) -> Variant:
	if property == "settings":
		return RubiconLevelNoteSettings.new()

	return
