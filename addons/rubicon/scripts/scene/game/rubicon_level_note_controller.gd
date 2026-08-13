@tool
class_name RubiconLevelNoteController extends Control

@export var chart: RubiChart:
	get:
		return _chart
	set(val):
		_chart = val
		_chart_dirty = true

@export var note_overrides: RubiconLevelNoteDatabase:
	get:
		return _override_note_database
	set(val):
		_override_note_database = val
		_reset_note_database()

@export var scroll_speed_multiplier: float = 1.0
@export var autoplay: bool = false
@export var preview_as_autoplay: bool = true
@export var inputs: RubiconLevelNoteInputMap


@export var disable_inputs: bool = false

@export_group("Offsets", "offset_")
@export var offset_input: float = 0.0
@export var offset_note_position: float = 0.0

@export_group("Performance", "performance_")
@export var performance_accuracy_percent: float = 100

@export_subgroup("Score", "performance_score_")
@export var performance_score_max: int = 1000000
@export var performance_score_value: int = 0

@export_subgroup("Combo", "performance_combo_")
@export var performance_combo_value: int = 0
@export var performance_combo_highest: int = 0

@export_subgroup("Hits", "performance_hits_")
@export var performance_hits_perfect: int
@export var performance_hits_great: int
@export var performance_hits_good: int
@export var performance_hits_okay: int
@export var performance_hits_bad: int
@export var performance_hits_miss: int

var note_handlers: Dictionary[String, RubiconLevelNoteHandler]

var _chart: RubiChart
var _chart_dirty: bool = false

var _level: RubiconLevel

var _override_note_database: RubiconLevelNoteDatabase
var _internal_note_database: Dictionary[StringName, RubiconLevelNoteMetadata]

static var is_playtesting: bool

signal note_changed(result: RubiconLevelNoteHitResult, has_ending_row: bool)
signal performance_updated

signal handler_just_pressed(handler_name: StringName)
signal handler_just_released(handler_name: StringName)

func _init() -> void :
	set_process_internal(true)

func get_note_database() -> Dictionary[StringName, RubiconLevelNoteMetadata]:
	return _internal_note_database

func update_chart() -> void :
	var metadata: RubiconLevelMetadata = get_level_metadata()
	if metadata == null or metadata.time_changes.is_empty():
		return

	_chart.initialize(metadata.time_changes)
	for id in note_handlers:
		note_handlers[id].update_notes()

func get_level_clock() -> RubiconLevelClock:
	if _level != null:
		return _level.clock

	return null

func get_level_metadata() -> RubiconLevelMetadata:
	if _level != null:
		return _level.metadata

	return null

func get_hit_count() -> int:
	var count: int = 0
	for key in note_handlers:
		var handler: RubiconLevelNoteHandler = note_handlers[key]
		count += handler.note_hit_index

	return count

func update_performance() -> void :
	var total_value: float = 0.0
	var note_count: int = 0
	var current_combo: int = 0
	var highest_combo: int = 0

	var results: Array[RubiconLevelNoteHitResult]
	for key in note_handlers:
		var handler: RubiconLevelNoteHandler = note_handlers[key]
		note_count += handler.data.size()

		if handler.note_hit_index >= handler.results.size():
			results.append_array(handler.results)
			continue

		var current_result: RubiconLevelNoteHitResult = handler.results[handler.note_hit_index]
		var target_index: int = handler.note_hit_index
		if current_result != null and current_result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
			target_index += 1

		for i in target_index:
			results.append(handler.results[i])

	results.sort_custom(RubiconLevelNoteHitResult.compare_results_by_time_hit)
	for result in results:
		total_value += result.scoring_value

		if result.handler.break_combo_indexes.has(result.data_index):
			current_combo = 0
			continue

		match result.scoring_rating:
			RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY, RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD, RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS:
				current_combo = 0
			_:
				current_combo += 1
				if current_combo > highest_combo:
					highest_combo = current_combo

	performance_combo_value = current_combo
	performance_combo_highest = highest_combo

	if performance_combo_highest == note_count and floori(total_value) == note_count:
		performance_score_value = performance_score_max
	else:
		var base_score: float = (total_value / note_count) * performance_score_max * 0.5
		var bonus_score: float = sqrt((float(performance_combo_highest) / note_count) * 100.0) * performance_score_max * 0.05
		performance_score_value = floori(base_score + bonus_score)

	performance_hits_perfect = _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT)
	performance_hits_great = _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT)
	performance_hits_good = _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD)
	performance_hits_okay = _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY)
	performance_hits_bad = _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD)
	performance_hits_miss = _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS)

	var total_hits: float = 0.0
	var accuracy_hits: float = 0.0
	for key: String in note_handlers:
		var handler: RubiconLevelNoteHandler = note_handlers[key]
		for i: int in handler.note_hit_index:
			var result: RubiconLevelNoteHitResult = handler.results[i]
			accuracy_hits += result.get_accuracy_value()
			total_hits += 1

	if total_hits == 0.0:
		performance_accuracy_percent = 100.0
	else:
		performance_accuracy_percent = (accuracy_hits / total_hits) * 100

	performance_updated.emit()

func _get_result_count_of_rating(rating: RubiconLevelNoteHitResult.Judgment) -> int:
	var count: int = 0
	for key in note_handlers:
		var handler: RubiconLevelNoteHandler = note_handlers[key]
		for i in handler.note_hit_index:
			var result: RubiconLevelNoteHitResult = handler.results[i]
			if result.scoring_rating != rating:
				continue

			count += 1

	return count

func _reset_note_database() -> void :
	_internal_note_database.clear()
	if _override_note_database != null:
		for key in _override_note_database.defines:
			_internal_note_database[key] = _override_note_database.defines[key]

	var default_database_path: String = ProjectSettings.get_setting("rubicon/defaults/note_database")
	if default_database_path.is_empty() or not ResourceLoader.exists(default_database_path):
		return

	var resource: Resource = ResourceLoader.load(default_database_path)
	if resource is not RubiconLevelNoteDatabase:
		update_chart()
		return

	for key in resource.defines:
		if _internal_note_database.has(key):
			continue

		_internal_note_database[key] = resource.defines[key]

	update_chart()

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_INTERNAL_PROCESS:
			if _chart_dirty:
				if _chart != null:
					update_chart()

				_chart_dirty = false
		NOTIFICATION_PARENTED:
			if _level != null:
				_level.changed.disconnect(update_chart)
				_level = null

			var parent: Node = get_parent()
			while parent != null:
				if parent is RubiconLevel:
					_level = parent
					_level.changed.connect(update_chart)
					break

				parent = parent.get_parent()

func _validate_property(property: Dictionary) -> void :
	var property_name: String = property.name
	if property_name.begins_with("performance_"):
		match property_name:
			"performance_score_max":
				property.usage = PROPERTY_USAGE_DEFAULT
			_:
				property.usage = PROPERTY_USAGE_EDITOR

func should_autoplay() -> bool:
	return autoplay or (preview_as_autoplay and Engine.is_editor_hint() and !is_playtesting)

func _input(event: InputEvent) -> void :
	if disable_inputs:
		return

	if should_autoplay() or event.is_echo() or inputs == null or not inputs.has_event_registered(event):
		return

	var id: StringName = inputs.get_handler_id_for_event(event)
	if not note_handlers.has(id):
		return

	var handler: RubiconLevelNoteHandler = note_handlers[id]
	if not handler._should_process():
		return

	if event.is_pressed():
		note_handlers[id]._press(event)
	else:
		note_handlers[id]._release(event)
