class_name HomeContainer
extends ConsoleTab

@export var select_bubble: Node2D
var bubble_target: Vector2
var time: float
signal disable_icons
signal enable_icons


func _process(delta: float) -> void :
	time += delta
	select_bubble.offset = Vector2(10 * sin(2 * time), 10 * cos(3 * time))

	if get_viewport().gui_get_focus_owner() and visible:
		select_bubble.position = lerp(select_bubble.position, bubble_target, delta * 10)
