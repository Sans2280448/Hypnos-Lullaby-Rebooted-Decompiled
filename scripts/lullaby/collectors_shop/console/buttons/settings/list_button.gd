class_name ListButton extends SettingsButton

@export var property: StringName
@export var display_list: Array[String]
@export var values_list: Array

var index: int
var initial_text: String

func _ready() -> void :
	super._ready()
	index = values_list.find(Settings.get(property))
	initial_text = text
	text = initial_text + str(display_list[index])

func _input(event: InputEvent) -> void :
	if not self.has_focus():
		return

	if event.is_action("ui_right") and not event.is_action_released("ui_right"):
		if index + 1 < values_list.size():
			console.play_sound.emit("sfx_soulroom_click")
			index += 1
			Settings.set(property, values_list[index])
			Settings.apply_settings()
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
			Settings.set(property, values_list[index])
			Settings.apply_settings()
			text = initial_text + str(display_list[index])
			if tween:
				tween.kill()
			tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_CUBIC)
		else:
			console.play_sound.emit("sfx_soulroom_deny")
