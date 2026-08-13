@tool
class_name LullabyVocalMuter
extends Node


@export var target_player: AudioStreamPlayer = null
@export var targets: Array[RubiconLevelNoteController] = []
@onready var miss_sfx: AudioStreamPlayer = get_child(0)


func _ready() -> void :
	for target: RubiconLevelNoteController in targets:
		target.note_changed.connect(_on_note_changed)
		for handler_id in target.note_handlers:
			var handler: RubiconLevelNoteHandler = target.note_handlers[handler_id]
			if handler is RubiconLevelManiaNoteHandler:
				handler.misplayed.connect(_on_misplay)

func _on_note_changed(result: RubiconLevelNoteHitResult, _has_ending_row: bool) -> void :
	if not is_instance_valid(target_player):
		return

	if result.scoring_rating == RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS:
		target_player.volume_linear = 0.0
		miss_sfx.pitch_scale = randf_range(0.95, 1.05)
		miss_sfx.play()
	else:
		target_player.volume_linear = 1.0

func _on_misplay(_lane_id: int) -> void :
	target_player.volume_linear = 0.0
	miss_sfx.pitch_scale = randf_range(0.95, 1.05)
	miss_sfx.play()
