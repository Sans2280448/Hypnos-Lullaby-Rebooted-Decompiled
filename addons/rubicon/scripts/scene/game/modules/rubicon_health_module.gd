@tool
extends Node
class_name RubiconHealthModule

@export var note_controller: RubiconLevelNoteController:
	set(value):
		if value == note_controller:
			return

		if is_tree_root and note_controller == null:
			printerr("Not recommended to assign a Note Controller on a character's scene (unless you know what you're doing!)")

		if value != note_controller and note_controller != null and note_controller.note_changed.is_connected(note_changed):
			note_controller.disconnect("note_changed", note_changed)
			note_controller_connected.emit(false)

		note_controller = value
		notify_property_list_changed()
		update_configuration_warnings()

		if note_controller != null:
			note_controller.connect("note_changed", note_changed)
			note_controller_connected.emit(true)

var is_tree_root: bool:
	get():
		if !is_inside_tree():
			return false

		if get_tree() != null and self == get_tree().edited_scene_root:
			return true
		return false

@export var min_health: float = 0.0
@export var max_health: float = 100.0
@export_storage var starting_health: float

var health: float:
	set(value):
		if value <= min_health:
			health = min_health
			health_changed.emit()
			health_depleted.emit()
			return
		elif value >= max_health:
			health = max_health
			health_changed.emit()
			return

		health = value
		health_changed.emit()

@export_storage var health_addition: Dictionary[StringName, float] = {}

signal health_changed
signal health_depleted

signal note_controller_connected(connected: bool)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if !is_tree_root and note_controller == null:
		warnings.append(tr("This health bar requires a note controller to function. Make sure to assign one on the inspector"))

	return warnings

func _ready() -> void :
	health = starting_health

func note_changed(result: RubiconLevelNoteHitResult, has_ending_row: bool = false) -> void :
	if result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_NONE:
		return

	if result.scoring_rating != RubiconLevelNoteHitResult.Judgment.JUDGMENT_NONE:
		var rating_name: StringName = RubiconLevelNoteHitResult.Judgment.find_key(result.scoring_rating)
		var health_addition: float = get(&"%s_health_addition" % [rating_name.to_lower().erase(0, 9)])
		if result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
			health_addition *= 0.5

		health += health_addition

@export_storage var perfect_health_addition: float = 3
@export_storage var great_health_addition: float = 2
@export_storage var good_health_addition: float = 1
@export_storage var okay_health_addition: float = -1
@export_storage var bad_health_addition: float = -2
@export_storage var miss_health_addition: float = -8
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary]

	properties.append({
		name = &"starting_health", 
		type = TYPE_FLOAT, 
		usage = PROPERTY_USAGE_DEFAULT, 
		hint = PROPERTY_HINT_NONE, 
	})





	if note_controller != null:
		properties.append({
			name = &"Health Addition", 
			type = TYPE_NIL, 
			usage = PROPERTY_USAGE_GROUP, 
		})

		properties.append({
			name = &"perfect_health_addition", 
			type = TYPE_FLOAT, 
			usage = PROPERTY_USAGE_DEFAULT, 
		})

		properties.append({
			name = &"great_health_addition", 
			type = TYPE_FLOAT, 
			usage = PROPERTY_USAGE_DEFAULT, 
		})

		properties.append({
			name = &"good_health_addition", 
			type = TYPE_FLOAT, 
			usage = PROPERTY_USAGE_DEFAULT, 
		})

		properties.append({
			name = &"okay_health_addition", 
			type = TYPE_FLOAT, 
			usage = PROPERTY_USAGE_DEFAULT, 
		})

		properties.append({
			name = &"bad_health_addition", 
			type = TYPE_FLOAT, 
			usage = PROPERTY_USAGE_DEFAULT, 
		})

		properties.append({
			name = &"miss_health_addition", 
			type = TYPE_FLOAT, 
			usage = PROPERTY_USAGE_DEFAULT, 
		})

	return properties

func _property_can_revert(property: StringName) -> bool:
	if property == &"starting_health":
		return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"starting_health":
			return (min_health + max_health) / 2

	return null

func _get(property: StringName) -> Variant:
	if property.ends_with("_health_addition"):
		if !health_addition.has(property):
			health_addition.set(property, _property_get_revert(property))
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property.ends_with("_health_addition"):
		health_addition.set(property, value)
		return true
	return false
