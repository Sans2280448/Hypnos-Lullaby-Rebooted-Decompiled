@tool
extends Node

@export var note_controller: RubiconLevelNoteController
@export var camera: Camera2D

@export_group("Movement")
@export var enabled: bool = true
@export var move_amount: float = 18.0
@export var camera_speed: float = 18.0

var current_offset: Vector2 = Vector2.ZERO
var target_offset: Vector2 = Vector2.ZERO
var last_lane_states: Dictionary[StringName, int] = {}

func _enter_tree() -> void :
	set_process(true)

func _process(delta: float) -> void :
	if camera == null:
		return

	target_offset = Vector2.ZERO

	if enabled and note_controller != null:
		target_offset = get_hit_offset()

	current_offset = current_offset.lerp(
		target_offset, 
		1.0 - exp( - camera_speed * delta)
	)

	camera.offset = current_offset


func get_hit_offset() -> Vector2:
	var final_offset: Vector2 = Vector2.ZERO

	for key: StringName in note_controller.note_handlers:
		var handler: RubiconLevelNoteHandler = note_controller.note_handlers[key]

		if handler is not RubiconLevelManiaNoteHandler:
			continue

		var mania_handler: RubiconLevelManiaNoteHandler = handler
		var lane_state: int = mania_handler.lane_state

		last_lane_states[key] = lane_state

		if lane_state != RubiconLevelManiaNoteHandler.LaneState.LANE_STATE_HIT:
			continue

		final_offset += lane_to_offset(mania_handler.lane_id)

	if final_offset.length() > move_amount:
		final_offset = final_offset.normalized() * move_amount

	return final_offset


func lane_to_offset(lane_id: int) -> Vector2:
	match lane_id:
		0:
			return Vector2( - move_amount, 0.0)
		1:
			return Vector2(0.0, move_amount)
		2:
			return Vector2(0.0, - move_amount)
		3:
			return Vector2(move_amount, 0.0)

	return Vector2.ZERO
