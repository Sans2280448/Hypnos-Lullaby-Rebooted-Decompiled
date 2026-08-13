@tool
extends Label


@export var divisor: String = "/"
@export var note_controller: RubiconLevelNoteController


func _process(_delta: float) -> void :
	if not note_controller:
		return

	text = "Score: %d %s Accuracy: %.2f%% %s Misses: %d" % [
		note_controller.performance_score_value, 
		divisor, 
		note_controller.performance_accuracy_percent, 
		divisor, 
		note_controller.performance_hits_miss, 
	]
