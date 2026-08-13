@tool
class_name LullabyRatingContainer extends Control


@export var level_note_controller: RubiconLevelNoteController:
	set(value):
		if (
			level_note_controller != null and 
			level_note_controller.note_changed.is_connected(note_changed)
		):
			level_note_controller.note_changed.disconnect(note_changed)

		level_note_controller = value
		update_configuration_warnings()

		if level_note_controller:
			level_note_controller.note_changed.connect(note_changed)

@export var perfect_sprite: Node2D
@export var great_sprite: Node2D
@export var good_sprite: Node2D
@export var okay_sprite: Node2D
@export var bad_sprite: Node2D
@export var combo_container: LullabyComboContainer

var rating_tween: Tween

var is_tree_root: bool:
	get():
		if not is_inside_tree():
			return false

		return get_tree() != null and self == get_tree().edited_scene_root


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not is_tree_root and level_note_controller == null:
		warnings.append(tr("This node requires a note controller to display judgements. Make sure to assign one in the inspector!"))

	return warnings


func _notification(what: int) -> void :
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			hide_all_ratings()


func note_changed(result: RubiconLevelNoteHitResult, _has_ending_row: bool = false) -> void :
	var hit_type: = result.scoring_hit
	var is_start: bool = (
		hit_type == RubiconLevelNoteHitResult.Hit.HIT_COMPLETE and 
		not _has_ending_row
	) or (
		hit_type == RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE and 
		_has_ending_row
	)

	if not is_start:
		return

	hide_all_ratings()

	match result.scoring_rating:
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT:
			perfect_sprite.show()
			tween_rating(perfect_sprite)
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT:
			great_sprite.show()
			tween_rating(great_sprite)
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD:
			good_sprite.show()
			tween_rating(good_sprite)
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY:
			okay_sprite.show()
			tween_rating(okay_sprite)
		RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD:
			bad_sprite.show()
			tween_rating(bad_sprite)


func hide_all_ratings() -> void :
	perfect_sprite.hide()
	great_sprite.hide()
	good_sprite.hide()
	okay_sprite.hide()
	bad_sprite.hide()


func tween_rating(sprite: Node2D) -> void :
	if rating_tween and rating_tween.is_running():
		rating_tween.kill()

	if combo_container:
		combo_container.scale = Vector2.ONE * 0.9
		combo_container.modulate.a = 1.0

	sprite.scale = Vector2.ONE * 1.1
	sprite.modulate.a = 1.0
	rating_tween = create_tween()\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_SINE)\
	.set_parallel()
	rating_tween.tween_property(sprite, ^"scale", Vector2.ONE, 0.25)
	rating_tween.tween_property(sprite, ^"modulate:a", 0.0, 0.75).set_delay(0.5)

	if combo_container:
		rating_tween.tween_property(
			combo_container, 
			^"scale", 
			Vector2.ONE * 0.75, 
			0.25
		)
		rating_tween.tween_property(
			combo_container, 
			^"modulate:a", 
			0.0, 
			0.75
		).set_delay(0.5)
