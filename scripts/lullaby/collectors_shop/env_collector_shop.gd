class_name CollectorShop
extends Node3D

enum ShopStates{
	BUSY = 0, 
	FREE_LOOK = 1, 
	FOCUSED = 2, 
}

static var previous_state: String = ""



static var last_trigger: TriggerArea3D
static var current_area: FocusArea3D:
	set(new_focus):
		if new_focus == current_area:
			return

		if current_area != null:
			current_area.is_focused = false
		if new_focus != null:
			new_focus.is_focused = true

		current_area = new_focus

@export var state: ShopStates = ShopStates.BUSY:
	set(value):
		state = value

		if mouse_controller != null:
			mouse_controller.should_cast_ray = value != ShopStates.BUSY

		if value != ShopStates.FREE_LOOK:
			_idle_timer = 0.0

@export var mouse_controller: MouseController
@export var sequence_controller: ShopSequences
@export var voiceline: AudioStreamPlayer3D
@export var voiceline_group_name: String
@export var voiceline_is_active: bool
@export var voiceline_is_skippable: bool
@export var dialogue: CollectorDialogue
@export var entry_voicelines: EntryVoicelines
@export var camera: RubiconInterpolatedCamera3D
@export var screen_transitions: AnimationPlayer
@export var fake_candle_shadow: Node3D

@export var voiceline_groups: Array[VoicelineGroup] = []

@export_group("Idle Voicelines")

@export var idle_voiceline_group: String = "idletoolong"
@export var idle_voiceline_time: float = 30.0

@onready var music: AudioStreamPlayer3D = $Audio / Music
@onready var collector: Collector = $Collector

@onready var voiceline_dial_end: Timer = %VoiceEndDialogueTimer
@onready var voiceline_state_end: Timer = %VoiceEndDialogueTimer

@export var skip_time: float = 0.1
@export var skips_needed: int = 3
@export var current_skips: int = 0

var regular_shop_music: AudioStream = preload("res://resources/audio/mus/mus_shop.ogg")

var _ending_dialogue: = false
var _current_ending_state: ShopStates = ShopStates.FREE_LOOK
var _group_indexes: Dictionary[String, int] = {}

var _idle_timer: float = 0.0

signal voice_entry_started(entry: VoicelineEntry)
signal voice_entry_finished()
signal voice_group_finished()
signal voice_interrupted()

func _ready() -> void :
	current_area = null
	last_trigger = null


	LullabyGameoverModule.has_died = false

	get_viewport().warp_mouse(get_viewport().get_visible_rect().size / 2)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if fake_candle_shadow != null:
		fake_candle_shadow.visible = false

	if voiceline != null and not voiceline.finished.is_connected(_on_voiceline_finished):
		voiceline.finished.connect(_on_voiceline_finished)

	if voiceline_dial_end:
		voiceline_dial_end.timeout.connect( func():
			if dialogue != null:
				dialogue.play_scale_out()

			if voiceline_state_end:
				voiceline_state_end.start()
		)

	if voiceline_state_end:
		voiceline_state_end.timeout.connect( func():
			if not current_area and _current_ending_state != ShopStates.BUSY:

				if _current_ending_state < ShopStates.FOCUSED:
					state = _current_ending_state
			_ending_dialogue = false
			_idle_timer = 0.0

			voiceline_state_end.stop()
		)

	if not SaveData.get_flag("intro_seen"):
		if sequence_controller != null and sequence_controller._animation_player != null:
			sequence_controller._animation_player.play("sequence_intro")

		SaveData.set_flag("intro_seen", true)

	elif SaveData.get_flag(&"credits_scroll_seen") and not SaveData.get_flag("outro_seen"):
		if sequence_controller != null and sequence_controller._animation_player != null:
			sequence_controller._animation_player.play("sequence_outro")

		SaveData.set_flag("outro_seen", true)
	else:
		match previous_state:
			"Kollectadex":
				default_entry()
				music.volume_linear = 0.0

				sequence_controller.animation_player.play(&"focus_left")

				screen_transitions.play(&"out")
				sequence_controller.animation_player.seek(0.0, true)

				camera.global_position = camera.position_interpolate_target + camera.position_interpolate_offset
				camera.global_rotation = camera.rotation_interpolate_target + camera.rotation_interpolate_offset
			_:
				default_shop()

	previous_state = ""

func _process(delta: float) -> void :
	if state != ShopStates.FREE_LOOK:
		return

	if _ending_dialogue:
		return

	_idle_timer += delta

	if _idle_timer >= idle_voiceline_time:
		_idle_timer = 0.0

		if idle_voiceline_group != "":
			play_voiceline_group("idletoolong", true)

func _input(event: InputEvent) -> void :
	if event.is_echo() or not event.is_pressed():
		return

	if event.is_action(&"ui_cancel"):
		if state == ShopStates.FOCUSED:
			sequence_controller.animation_player.play(&"focus_center")

func default_shop(play_voicelines: bool = true) -> void :
	default_entry()

	if play_voicelines and entry_voicelines != null:
		entry_voicelines.play_entry_voiceline()

func default_entry() -> void :
	music.stream = regular_shop_music
	music.volume_db = -24.124
	music.play()

	collector_unseen()

func save_collector_memory() -> void :
	SaveData.save()

func collector_unseen() -> void :
	if state != ShopStates.BUSY and state != ShopStates.FOCUSED:
		collector.play_random_idle()

func _check_voiceline_group(group_name):
	var group: = get_voiceline_group(group_name)

	if group == null:
		push_warning("Missing voiceline group: " + group_name)
		return null

	if group.voicelines.is_empty():
		push_warning("Voiceline group is empty: " + group_name)
		return null

	return group


func play_full_voiceline_group(group_name: String, from_start: bool = true) -> void :
	var group: VoicelineGroup = _check_voiceline_group(group_name)

	if group == null:
		return

	voiceline_group_name = group_name
	if from_start:
		_group_indexes.set(group_name, 0)

	_next_line = func _next():
		var index: = _group_indexes.get(group_name, 0) as int

		if index >= group.voicelines.size():
			_group_indexes.set(group_name, 0)

			_next_line = null
			_on_voiceline_finished()

			voiceline_group_name = ""
			voice_group_finished.emit()

			return

		var entry: VoicelineEntry = _get_next_ordered_voiceline(group_name, group, false)
		play_voiceline_entry(entry, true)

	_next_line.call()


func play_voiceline_group(group_name: String, _randomize: bool = true, _wrap_index: bool = true) -> void :
	var group: VoicelineGroup = _check_voiceline_group(group_name)

	if group == null:
		return

	voiceline_group_name = group_name
	var entry: VoicelineEntry

	if _randomize:
		entry = group.voicelines.pick_random()
	else:
		entry = _get_next_ordered_voiceline(group_name, group, _wrap_index)

	play_voiceline_entry(entry, false)

func _get_next_ordered_voiceline(group_name: String, group: VoicelineGroup, wrap_index: bool = true) -> VoicelineEntry:
	var index: = _group_indexes.get(group_name, 0) as int

	if wrap_index:
		index = wrapi(index, 0, group.voicelines.size())
		_group_indexes[group_name] = wrapi(index + 1, 0, group.voicelines.size())
	else:
		index = index
		_group_indexes[group_name] = index + 1

	return group.voicelines[index]

func play_voiceline_entry(entry: VoicelineEntry, skippable: bool = false) -> void :
	if entry == null:
		return

	_idle_timer = 0.0
	_ending_dialogue = false


	if entry.state < ShopStates.FOCUSED:
		state = entry.state as ShopStates
	if entry.ending_state > ShopStates.FOCUSED:
		_current_ending_state = 3

	if dialogue != null:
		dialogue.start_dialogue([entry.dialogue_text])

	if voiceline == null:
		_on_voiceline_finished()
		return

	voiceline.stop()
	voiceline.stream = entry.stream

	if entry.stream != null:
		voiceline.play()
	else:
		_on_voiceline_finished()

	voiceline_is_skippable = skippable

	voiceline_is_active = true
	voice_entry_started.emit(entry)

	voiceline_dial_end.stop()
	voiceline_state_end.stop()

func stop_voiceline():
	_next_line = null

	_idle_timer = 0.0
	_ending_dialogue = false

	voiceline_is_skippable = false
	voiceline_group_name = ""

	if dialogue != null:
		dialogue.end_dialogue()

	_on_voiceline_finished()
	voiceline.stop()

	voiceline_dial_end.stop()
	voiceline_state_end.stop()

func get_voiceline_group(group_name: String) -> VoicelineGroup:
	for group in voiceline_groups:
		if group != null and group.group_name == group_name:
			return group

	return null

var _next_line = null

func _on_voiceline_finished() -> void :
	voiceline_is_active = false;
	voice_entry_finished.emit()

	if _next_line != null:
		if not voiceline_is_skippable:
			_next_line.call()
		return
	else:
		voiceline_group_name = ""

	if _ending_dialogue:
		return

	_ending_dialogue = true
	voiceline_dial_end.start()

var _skipped_time: float = -1

func skip_voiceline() -> void :
	voiceline.stop()
	_on_voiceline_finished()

	dialogue.finish_line()

	var current_time: float = Time.get_ticks_msec() / 1000.0

	if _skipped_time == -1:
		_skipped_time = current_time;
		return

	var time_diff: float = (current_time - _skipped_time)

	if time_diff < skip_time:
		current_skips += 1
		if current_skips >= skips_needed:
			voice_interrupted.emit()

			current_skips = 0
	else:
		current_skips = 0

	_skipped_time = current_time


func _exit_tree() -> void :
	last_trigger = null
	current_area = null
