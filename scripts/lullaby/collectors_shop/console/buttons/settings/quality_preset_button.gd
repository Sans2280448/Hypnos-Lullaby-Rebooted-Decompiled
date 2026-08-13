extends SettingsButton

@export var display_list: Array[String]
@export var values_list: Array

var index: int
var initial_text: String

func _ready() -> void :
	super._ready()
	initial_text = text
	if Settings.get_quality_preset():
		match Settings.get_quality_preset():
			Settings.PRESET_LOW:
				index = 0
			Settings.PRESET_MEDIUM:
				index = 1
			Settings.PRESET_HIGH:
				index = 2
		text = initial_text + str(display_list[index])
	else:
		index = -1
		text = initial_text + "Custom"

func _input(event: InputEvent) -> void :
	if not self.has_focus():
		return

	if event.is_action("ui_right") and not event.is_action_released("ui_right"):
		if index + 1 < values_list.size():
			console.play_sound.emit("sfx_soulroom_click")
			index += 1
			match index:
				0:
					Settings.PRESET_LOW.apply(Settings)
				1:
					Settings.PRESET_MEDIUM.apply(Settings)
				2:
					Settings.PRESET_HIGH.apply(Settings)
			text = initial_text + str(display_list[index])
			if tween:
				tween.kill()
			tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_CUBIC)
		else:
			console.play_sound.emit("sfx_soulroom_deny")

	if event.is_action("ui_left") and not event.is_action_released("ui_left"):
		if index - 1 >= 0:
			console.play_sound.emit("sfx_soulroom_click")
			index -= 1
			match index:
				0:
					Settings.PRESET_LOW.apply(Settings)
				1:
					Settings.PRESET_MEDIUM.apply(Settings)
				2:
					Settings.PRESET_HIGH.apply(Settings)
			text = initial_text + str(display_list[index])
			if tween:
				tween.kill()
			tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_CUBIC)
		else:
			console.play_sound.emit("sfx_soulroom_deny")
