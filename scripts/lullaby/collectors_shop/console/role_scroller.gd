extends Control

@export var nonscroll_label: Label
@export var scroll_label: Label
@export var parent_container: Control
@export var scroll_container: ScrollContainer
@export var text: String
@export var limit_until_scroll: int
@export var time_to_start_scrolling: float = 1
var is_scrolling: bool
var cloned_label: Label
var frames_until_next_scroll: int = 0

var _time_until_scroll: float = 0.0

func _ready() -> void :
	cloned_label = scroll_label.duplicate()
	scroll_container.get_child(0).add_child(cloned_label)

func _process(delta: float) -> void :
	if not parent_container.visible or not is_scrolling:
		return

	if _time_until_scroll > 0:
		_time_until_scroll -= delta
		return

	if frames_until_next_scroll == 0:
		frames_until_next_scroll = 2
		scroll_container.scroll_horizontal += 1
		if scroll_container.scroll_horizontal >= scroll_label.size.x:
			scroll_container.scroll_horizontal = 0
	else:
		frames_until_next_scroll -= 1

func _on_credits_container_changed_credits_entry() -> void :
	scroll_container.scroll_horizontal = 0
	_time_until_scroll = time_to_start_scrolling

	is_scrolling = text.length() > limit_until_scroll

	if not is_scrolling:
		nonscroll_label.text = text
		nonscroll_label.visible = true
		scroll_container.visible = false
		return

	scroll_label.text = text + "             "
	cloned_label.text = text
	nonscroll_label.visible = false
	scroll_container.visible = true
