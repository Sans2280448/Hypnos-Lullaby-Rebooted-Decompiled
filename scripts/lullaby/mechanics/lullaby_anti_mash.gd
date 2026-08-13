class_name LullabyAntiMash extends Node

@export var enabled: bool = true
@export var mash_threshold: int = 8
@export var time_until_reset: float = 2.5
@export var note_disable_window: float = 0.5

var _controller: RubiconLevelNoteController
var _last_indexes: Dictionary[StringName, int] = {}

var _mash_counter: int = 0
var _mash_timer: float = 0

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_PARENTED:
			if _controller and _controller.handler_just_pressed.is_connected(_on_press):
				_controller.handler_just_pressed.disconnect(_on_press)

			_controller = null

			var parent: Node = get_parent()
			if parent is RubiconLevelNoteController:
				_controller = parent
				_controller.handler_just_pressed.connect(_on_press)

func _process(delta: float) -> void :
	if not _controller:
		return

	update_timer(delta)

func update_timer(delta: float) -> void :
	if not enabled or _mash_timer <= 0:
		_mash_counter = 0
		return

	_mash_timer -= delta
	if _mash_timer <= 0:
		for controller_handler in _controller.note_handlers.values():
			controller_handler.modulate.a = 1.0

		_controller.disable_inputs = false

func _on_press(id: StringName) -> void :
	var handler: RubiconLevelNoteHandler = _controller.note_handlers[id]
	var note_is_near: bool = handler.note_hit_index < handler.data.size() and (abs(_controller.get_level_clock().get_time_precise() - handler.data[handler.note_hit_index].get_millisecond_start_position()) / 1000.0) < note_disable_window
	var was_note_changed: bool = handler.last_hit_note_index != _last_indexes.get(id, -1)

	if note_is_near and not was_note_changed:
		_mash_counter += 1
		_mash_timer = time_until_reset

		if _mash_counter >= mash_threshold:
			for controller_handler in _controller.note_handlers.values():
				controller_handler._release(InputEventAction.new())
				controller_handler.modulate.a = 0.5

			_controller.disable_inputs = true

	_last_indexes[id] = handler.last_hit_note_index
