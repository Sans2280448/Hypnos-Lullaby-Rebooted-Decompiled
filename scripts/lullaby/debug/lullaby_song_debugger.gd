class_name LullabySongDebugger extends Node

@export var level: RubiconLevel
@export var controller_to_watch: RubiconLevelNoteController

@export var container: Control
@export var song_name_label: Label
@export var debug_only_container: Control
@export var seconds_counter: SpinBox
@export var measure_counter: SpinBox
@export var beats_counter: SpinBox
@export var steps_counter: SpinBox
@export var controller_info_label: Label

func _ready() -> void :
	song_name_label.text = level.metadata.title

func _process(_delta: float) -> void :
	update_visibility()

	if not debug_only_container.visible:
		return

	var clock: RubiconLevelClock = level.clock
	if not seconds_counter.has_focus():
		seconds_counter.set_value_no_signal(clock.time_milliseconds / 1000.0)

	if not measure_counter.has_focus():
		measure_counter.set_value_no_signal(clock.time_measure)

	if not beats_counter.has_focus():
		beats_counter.set_value_no_signal(clock.time_beat)

	if not steps_counter.has_focus():
		steps_counter.set_value_no_signal(clock.time_step)

	if controller_to_watch == null:
		controller_info_label.text = "Watching nothing"
		return

	controller_info_label.text = "Watching \"%s\"" % controller_to_watch.name
	controller_info_label.text += "\nPerfect: %s" % controller_to_watch.performance_hits_perfect
	controller_info_label.text += "\nGreat: %s" % controller_to_watch.performance_hits_great
	controller_info_label.text += "\nGood: %s" % controller_to_watch.performance_hits_good
	controller_info_label.text += "\nOkay: %s" % controller_to_watch.performance_hits_okay
	controller_info_label.text += "\nBad: %s" % controller_to_watch.performance_hits_bad
	controller_info_label.text += "\nMiss: %s" % controller_to_watch.performance_hits_miss

func update_visibility() -> void :
	match Debugger.fps_display.current_state:
		LullabyFPSDisplay.CurrentState.NONE:
			container.visible = false
			debug_only_container.visible = false
		LullabyFPSDisplay.CurrentState.BASIC:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			container.visible = true
			debug_only_container.visible = false
		LullabyFPSDisplay.CurrentState.ADVANCED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			container.visible = true
			debug_only_container.visible = true

func _on_seconds_updated(value: float) -> void :
	level.clock.time_milliseconds = value * 1000.0

func _on_measure_updated(value: float) -> void :
	level.clock.time_measure = value

func _on_beat_updated(value: float) -> void :
	level.clock.time_beat = value

func _on_step_updated(value: float) -> void :
	level.clock.time_step = value
