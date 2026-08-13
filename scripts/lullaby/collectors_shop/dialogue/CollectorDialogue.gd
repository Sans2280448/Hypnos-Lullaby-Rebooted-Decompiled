@tool
class_name CollectorDialogue
extends Control

const PAUSE_TAG: = "[pause]"

const START_SCALE: = Vector2(1.2, 1.2)
const NORMAL_SCALE: = Vector2.ONE
const OVERSHOOT_SCALE: = Vector2(0.95, 0.95)

const SCALE_IN_TIME: = 0.5
const SETTLE_TIME: = 0.43
const SCALE_OUT_TIME: = 0.5

@export var seconds_per_character: float = 0.055
@export_multiline var dialogue_text: String = ""

@onready var text: RichTextLabel = $Text
@onready var skip_text: RichTextLabel = $"Skip Text"
@onready var background: TextureRect = $Background

@export var shop: CollectorShop

var dialogue_lines: Array[String] = []
var current_line_index: int = 0

var is_typing: bool = false
var typing_paused: bool = false

var _typing_time: float = 0.0
var _raw_index: int = 0
var _visible_characters: int = 0
var _current_line: String = ""
var _display_line: String = ""
var _scale_tween: Tween
var _up_tween: Tween


func _ready() -> void :
	text.text = ""
	text.visible_characters = -1

	skip_text.visible_characters = -1

	scale = Vector2.ZERO
	visible = false


func _process(delta: float) -> void :
	if shop.voiceline_is_skippable:
		background.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		if _mouse_on_background and Input.is_action_just_released("left_click"):
			if skip_text.visible:
				if shop._next_line != null:
					shop._next_line.call()
			else:
				shop.skip_voiceline()
	else:
		background.mouse_default_cursor_shape = Control.CURSOR_ARROW

	if not is_typing or typing_paused:
		return

	_typing_time += delta

	while _typing_time >= seconds_per_character:
		_typing_time -= seconds_per_character
		type_next_character()

		if typing_paused or not is_typing:
			break


func start_dialogue(lines: Array[String]) -> void :
	dialogue_lines = lines
	current_line_index = 0
	cancel_scale()
	play_scale_in()
	show_line()


func start_dialogue_from_text() -> void :
	dialogue_lines.clear()

	for line in dialogue_text.split("\n"):
		dialogue_lines.append(line)

	current_line_index = 0
	play_scale_in()
	show_line()


func show_line() -> void :
	if current_line_index >= dialogue_lines.size():
		end_dialogue()
		return

	_current_line = dialogue_lines[current_line_index]
	_display_line = _current_line.replace(PAUSE_TAG, "")

	_raw_index = 0
	_visible_characters = 0
	_typing_time = 0.0
	typing_paused = false

	text.text = _display_line
	text.visible_characters = 0

	is_typing = true


func type_next_character() -> void :
	if _raw_index >= _current_line.length():
		finish_line()
		return

	if _current_line.substr(_raw_index, PAUSE_TAG.length()) == PAUSE_TAG:
		_raw_index += PAUSE_TAG.length()
		typing_paused = true
		return

	if _current_line[_raw_index] == "[":
		var end_tag_index: = _current_line.find("]", _raw_index)

		if end_tag_index != -1:
			_raw_index = end_tag_index + 1
			type_next_character()
			return

	_raw_index += 1
	_visible_characters += 1
	text.visible_characters = _visible_characters

	if _raw_index >= _current_line.length():
		finish_line()


func resume_typing() -> void :
	typing_paused = false


func next_line() -> void :
	if is_typing or typing_paused:
		finish_line()
		return

	current_line_index += 1
	show_line()


func finish_line() -> void :
	text.text = _display_line
	text.visible_characters = -1

	_raw_index = _current_line.length()
	is_typing = false
	typing_paused = false


func end_dialogue() -> void :
	is_typing = false
	typing_paused = false
	dialogue_lines.clear()
	current_line_index = 0

	play_scale_out()


func clear_dialogue_text() -> void :
	text.text = ""
	text.visible_characters = -1


func play_scale_in() -> void :
	if _scale_tween != null:
		_scale_tween.kill()

	make_visible()
	modulate.a = 0

	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_BACK)
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, "modulate:a", 1, SETTLE_TIME)

func play_scale_out() -> void :
	if _scale_tween != null:
		_scale_tween.kill()

	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_CUBIC)
	_scale_tween.set_ease(Tween.EASE_IN)
	_scale_tween.tween_property(self, "scale", Vector2.ZERO, SCALE_OUT_TIME)
	_scale_tween.finished.connect( func():
		visible = false
		clear_dialogue_text()
	)



func play_move_up() -> void :
	if _up_tween != null:
		_up_tween.custom_step(9999)
		_up_tween.kill()

	_up_tween = create_tween()
	_up_tween.set_trans(Tween.TRANS_CUBIC)
	_up_tween.set_ease(Tween.EASE_IN)
	_up_tween.tween_property(self, "position:y", position.y - 30.0, SCALE_OUT_TIME)



func play_move_down() -> void :
	if _up_tween != null:
		_up_tween.custom_step(9999)
		_up_tween.kill()

	_up_tween = create_tween()
	_up_tween.set_trans(Tween.TRANS_CUBIC)
	_up_tween.set_ease(Tween.EASE_IN)
	_up_tween.tween_property(self, "position:y", position.y + 30.0, SCALE_OUT_TIME)

func cancel_scale() -> void :
	if _scale_tween != null:
		_scale_tween.kill()

func make_visible() -> void :
	visible = true
	modulate.a = 1.0
	scale = NORMAL_SCALE

var _mouse_on_background: bool = false

func _on_background_mouse_entered() -> void :
	_mouse_on_background = true

func _on_background_mouse_exited() -> void :
	_mouse_on_background = false

var _skip_tween: Tween = null

func _on_collector_shop_voice_entry_finished() -> void :
	if shop.voiceline_is_skippable and not skip_text.visible:
		skip_text.scale = Vector2.ZERO
		skip_text.modulate.a = 0.0
		skip_text.visible = true

		if _skip_tween != null:
			_skip_tween.custom_step(999)
			_skip_tween.kill()
			_skip_tween = null

		_skip_tween = create_tween()
		_skip_tween.tween_method(
			func update(val: float):
				var scale_val: float = EasingFunctions.ease_in_out_circ(0.9, 1.0, val)
				skip_text.scale = Vector2(scale_val, 1.0)

				var alpha_val: float = EasingFunctions.ease_in_cubic(0.0, 1.0, val)
				skip_text.modulate.a = alpha_val, 
			0.0, 
			1.0, 
			0.5
		)

func _on_collector_shop_voice_entry_started(entry: VoicelineEntry) -> void :
	skip_text.visible = false
