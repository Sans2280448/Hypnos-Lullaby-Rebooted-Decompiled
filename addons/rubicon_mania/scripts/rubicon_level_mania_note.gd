@tool
class_name RubiconLevelManiaNote extends RubiconLevelNote

@export var lane_id: int = 0
@export var local_direction: float = 0.0

@export_group("Offset", "offset_")
@export var offset_position: Vector2
@export var offset_rotation: float
@export var offset_scale: Vector2 = Vector2.ONE

@export_group("References", "reference_")
@export var reference_graphic: Control
@export var reference_trail: Control
@export var reference_container: Control

func get_mania_handler() -> RubiconLevelManiaNoteHandler:
	return _handler

func initialize(handler: RubiconLevelNoteHandler, data_index: int) -> void :
	super (handler, data_index)

	lane_id = get_mania_handler().lane_id

	var final_rotation: float = get_mania_handler().global_direction + local_direction
	position = Vector2(cos(final_rotation), sin(final_rotation)) * 5000.0

	reference_container.offset_left = 0.0
	reference_container.pivot_offset.x = - reference_container.offset_left

	var controller: RubiconLevelNoteController = get_mania_handler().get_controller()
	reference_container.offset_right = floor(controller.chart.scroll_multiplier * controller.scroll_speed_multiplier * (handler.data[data_index].get_graphical_end_position() - handler.data[data_index].get_graphical_start_position()))

func _process(delta: float) -> void :
	if not _should_process():
		return

	var handler: RubiconLevelManiaNoteHandler = get_mania_handler()
	var controller: RubiconLevelNoteController = handler.get_controller()

	var final_rotation: float = handler.global_direction + local_direction
	reference_container.rotation = final_rotation
	reference_graphic.rotation = - final_rotation

	var current_time: float = controller.get_level_clock().time_milliseconds + controller.offset_note_position
	var current_start_position: float = controller.chart.scroll_multiplier * controller.scroll_speed_multiplier * handler.data[data_index].get_graphical_start_position_relative(current_time)


	var rotation_vector: Vector2 = Vector2(cos(final_rotation), sin(final_rotation))
	position = (rotation_vector * current_start_position) + (rotation_vector * offset_position)

	if handler.data[data_index].ending_row != null:
		if was_hit() and not was_missed():
			reference_container.offset_left = floor(reference_container.offset_right - (controller.chart.scroll_multiplier * controller.scroll_speed_multiplier * handler.data[data_index].get_graphical_end_position_relative(current_time)))
			reference_container.pivot_offset.x = - reference_container.offset_left
		elif not was_hit():
			reference_container.offset_left = 0.0
			reference_container.pivot_offset.x = - reference_container.offset_left
