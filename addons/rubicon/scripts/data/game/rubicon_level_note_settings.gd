@tool
class_name RubiconLevelNoteSettings extends Resource

@export_category("Judgments")
@export_flags("Perfect:2", "Great:4", "Good:8", "Okay:16", "Bad:32") var judgment_enabled: int:
	get:
		return _judgments_enabled
	set(val):
		_judgments_enabled = val
		notify_property_list_changed()

@export_group("Windows", "judgment_window_")
@export_range(0.0, 130, 0.01, "or_greater") var judgment_window_perfect: float = 20
@export_range(0.0, 130, 0.01, "or_greater") var judgment_window_great: float = 45
@export_range(0.0, 130, 0.01, "or_greater") var judgment_window_good: float = 75
@export_range(0.0, 130, 0.01, "or_greater") var judgment_window_okay: float = 105
@export_range(0.0, 130, 0.01, "or_greater") var judgment_window_bad: float = 130

var _judgments_enabled: int = 63

func _validate_property(property: Dictionary) -> void :
	if property.name.begins_with("judgment_window_"):
		var judgment_name: String = property.name.replace("judgment_window_", "")
		match judgment_name:
			"perfect":
				_validate_judgment(property, judgment_name, RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT)
			"great":
				_validate_judgment(property, judgment_name, RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT)
			"good":
				_validate_judgment(property, judgment_name, RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD)
			"okay":
				_validate_judgment(property, judgment_name, RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY)
			"bad":
				_validate_judgment(property, judgment_name, RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD)

func _property_can_revert(property: StringName) -> bool:
	if property == "judgment_enabled":
		return true

	return false

func _property_get_revert(property: StringName) -> Variant:
	if property == "judgment_enabled":
		return 63

	return

func _validate_judgment(property: Dictionary, judgment_name: String, judgment_value: RubiconLevelNoteHitResult.Judgment) -> void :
	if property.name == "judgment_window_%s" % judgment_name:
		if not _check_for_judgment(judgment_enabled, judgment_value):
			property.usage = PROPERTY_USAGE_NONE
		else:
			property.usage = PROPERTY_USAGE_DEFAULT

func _check_for_judgment(flags: int, judgment: RubiconLevelNoteHitResult.Judgment) -> bool:
	return flags & judgment == judgment
