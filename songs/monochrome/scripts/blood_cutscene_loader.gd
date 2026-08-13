extends Node

@export var clock: RubiconLevelClock
@export var placement: Node
@export var opponent_controller: RubiconLevelNoteController
@export var player_controller: RubiconLevelNoteController
@export var execution_time: float = 152 * 1000
@export var nodes_to_free: Array[Node] = []
@export_file("*.tscn", "*.scn") var blood_cutscene_path: String
@export_file("*.tscn", "*.scn") var blood_gold_path: String
@export_file("*.tscn", "*.scn") var blood_bf_path: String
@export_file("*.tscn", "*.scn") var bf_scream_path: String
@export_file("*.tscn", "*.scn") var mono_closeup_path: String

var _scenes_to_load: Array[String] = []

var _activated: bool = false

var _load_progress: Array[float] = [0.0]
var _loaded: bool = false

var _blood_cutscene: Node
var _blood_gold: Node
var _blood_bf: Node

var _bf_scream: Node
var _mono_closeup: Node

func _process(_delta: float) -> void :
	if not clock:
		return

	if not _activated:
		_preactivation()
	elif not _loaded:
		_when_activated()

func _preactivation() -> void :
	if clock.time_milliseconds < execution_time:
		return

	_activated = true
	for node in nodes_to_free:
		node.queue_free()

	nodes_to_free.clear()

	_scenes_to_load = [blood_cutscene_path, blood_gold_path, blood_bf_path, bf_scream_path, mono_closeup_path]
	for path in _scenes_to_load:
		ResourceLoader.load_threaded_request(path)

func _when_activated() -> void :
	for path in _scenes_to_load:
		match ResourceLoader.load_threaded_get_status(path, _load_progress):
			ResourceLoader.THREAD_LOAD_FAILED:
				_loaded = true
				ErrorHandler.show_warning("Could not load scene %s" % path, ERR_CANT_ACQUIRE_RESOURCE)
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				pass


			ResourceLoader.THREAD_LOAD_LOADED:
				_scenes_to_load.erase(path)

				var node: Node = ResourceLoader.load_threaded_get(path).instantiate()
				match path:
					blood_cutscene_path:
						_blood_cutscene = node
					blood_gold_path:
						_blood_gold = node
					blood_bf_path:
						_blood_bf = node
					bf_scream_path:
						_bf_scream = node
					mono_closeup_path:
						_mono_closeup = node

	if _scenes_to_load.is_empty():
		_loaded = true

		_blood_cutscene.visible = false
		placement.add_child(_blood_cutscene)

		_blood_cutscene.add_child(_blood_gold)
		_blood_cutscene.add_child(_blood_bf)

		_blood_gold.position = Vector2(678, 527)
		_blood_gold.level_note_controller = opponent_controller

		_blood_bf.position = Vector2(1294, 594)
		_blood_bf.level_note_controller = player_controller

		placement.add_child(_bf_scream)
		_bf_scream.visible = false

		placement.add_child(_mono_closeup)
		_mono_closeup.visible = false

		clock.animation_player.clear_caches()
