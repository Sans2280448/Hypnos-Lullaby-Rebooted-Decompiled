@tool
extends RubiconCharacter

@export var gunk_animation_player: AnimationPlayer

func note_changed(result: RubiconLevelNoteHitResult, has_ending_row: bool = false) -> void :
	super.note_changed(result, has_ending_row)

	_last_sing_anim = get_anim_alias_from_result(result)

	match result.scoring_hit:
		RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
			gunk_animation_player.play(_last_sing_anim)
		RubiconLevelNoteHitResult.Hit.HIT_COMPLETE:
			if has_ending_row:
				return
			gunk_animation_player.play(_last_sing_anim)
