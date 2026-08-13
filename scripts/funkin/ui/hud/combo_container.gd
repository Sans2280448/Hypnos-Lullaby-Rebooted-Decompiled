@tool
class_name LullabyComboContainer extends Control


@export var level_note_controller: RubiconLevelNoteController:
	set(value):
		if (
			level_note_controller != null and 
			level_note_controller.performance_updated.is_connected(_performance_updated)
		):
			level_note_controller.performance_updated.disconnect(_performance_updated)

		level_note_controller = value
		update_configuration_warnings()

		if level_note_controller:
			level_note_controller.performance_updated.connect(_performance_updated)

@export var combo_template: PackedScene

var is_tree_root: bool:
	get():
		if not is_inside_tree():
			return false

		return get_tree() != null and self == get_tree().edited_scene_root


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not is_tree_root and level_note_controller == null:
		warnings.append(tr("This node requires a note controller to display combo. Make sure to assign one in the inspector!"))

	return warnings


func _notification(what: int) -> void :
	match what:
		NOTIFICATION_READY:
			_clear_children()


func _performance_updated() -> void :
	_clear_children()

	var combo: int = level_note_controller.performance_combo_value
	if combo == 0:
		return

	var digits: String = str(combo)
	var count: int = digits.length()
	for i: int in count:
		var number: int = int(digits[i])

		var digit_sprite: AnimatedSprite2D = combo_template.instantiate()
		digit_sprite.frame = number
		digit_sprite.position.x = -26.0 * (count - 1) + (52.0 * (i))
		add_child(digit_sprite)


func _clear_children() -> void :
	while get_child_count() > 0:
		var child: Node = get_child(0)
		remove_child(child)
		child.queue_free()
