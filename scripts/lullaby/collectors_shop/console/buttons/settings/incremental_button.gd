class_name IncrementalSettingsButton
extends SettingsButton

@export var property: StringName
var value: float
@export var is_percent: bool = false
@export var increment_amount: float
@export var value_max: float
@export var value_min: float
@export var suffix: String
var initial_text: String

func _ready() -> void :
	super ()
	value = Settings.get(property)
	initial_text = text
	update_text()

func _input(event: InputEvent) -> void :
	if not self.has_focus():
		return

	if event.is_action("ui_right") and not event.is_action_released("ui_right"):
		if value + increment_amount <= value_max:
			console.play_sound.emit("sfx_soulroom_click")
			value += increment_amount
			value = snappedf(value, increment_amount)
			Settings.set(property, value)
			Settings.apply_settings()
			update_text()
			if tween:
				tween.kill()
			tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_CUBIC)
		else:
			console.play_sound.emit("sfx_soulroom_deny")

	if event.is_action("ui_left") and not event.is_action_released("ui_left"):
		if value - increment_amount >= value_min:
			console.play_sound.emit("sfx_soulroom_click")
			value -= increment_amount
			value = snappedf(value, increment_amount)
			Settings.set(property, value)
			update_text()
			if tween:
				tween.kill()
			tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_CUBIC)
		else:
			console.play_sound.emit("sfx_soulroom_deny")

func update_text() -> void :
	var display_value: float = value if not is_percent else floorf(value * 100.0)
	text = initial_text + (str("%.f" % display_value) if is_equal_approx(display_value, roundf(display_value)) else str(display_value)) + suffix
