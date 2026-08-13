@tool
class_name RubiconLevelNoteMetadata extends Resource

@export var scene: PackedScene

@export_group("Predefines", "predefine_")
@export var predefine_should_miss: bool = false
@export var predefine_count_towards_score: bool = true

func note_hit(result: RubiconLevelNoteHitResult) -> RubiconLevelNoteHitResult:
	return result
