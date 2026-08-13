extends Node

@export var connect_to: TypingChallenge
@export var clock: RubiconLevelClock

@export var custom_word_list: Array[TypingCustomWord]

var _custom_word_index: int = 0

func _ready() -> void :
	for custom_word in custom_word_list:
		if not SaveData.has_flag(custom_word.flag):
			SaveData.set_flag(custom_word.flag, false)

	_go_to_next_custom_word()
	connect_to.challenge_started.connect(_on_challenge_started)

func _process(_delta: float) -> void :
	if not _is_current_index_valid():
		connect_to.choose_from_list = true
		return

	var current: TypingCustomWord = _get_current_custom_word()
	if clock.time_milliseconds >= current.time_start and clock.time_milliseconds <= current.time_end:
		connect_to.choose_from_list = false
		connect_to.custom_word = current.word
	else:
		connect_to.choose_from_list = true

func _on_challenge_started() -> void :
	if not _is_current_index_valid():
		return

	var current: TypingCustomWord = _get_current_custom_word()
	if connect_to.custom_word == current.word:
		SaveData.set_flag(current.flag, true)
		_go_to_next_custom_word()

func _go_to_next_custom_word() -> void :
	while _is_current_index_valid():
		var current: TypingCustomWord = _get_current_custom_word()
		if not SaveData.get_flag(current.flag):
			break

		_custom_word_index += 1

func _is_current_index_valid() -> bool:
	return _custom_word_index < custom_word_list.size()

func _get_current_custom_word() -> TypingCustomWord:
	return custom_word_list[_custom_word_index]
