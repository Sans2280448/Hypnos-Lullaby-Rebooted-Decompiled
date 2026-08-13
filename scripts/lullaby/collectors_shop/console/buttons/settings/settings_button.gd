extends Button
class_name SettingsButton

@export var console: Control
@export_multiline() var tooltip: String
var tooltip_node: Label
var tween: Tween

func _ready() -> void :
	tooltip_node = %Tooltip
	pivot_offset_ratio.y = 0.5
	self.focus_entered.connect(_on_focus_entered)
	self.focus_exited.connect(_on_focus_exited)
	self.pressed.connect(_on_button_pressed)

func _on_focus_entered():
	tooltip_node.text = tooltip
	console.play_sound.emit("sfx_soulroom_click")
	modulate = Color.YELLOW
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_CUBIC)

func _on_focus_exited():
	modulate = Color.WHITE
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_CUBIC)

func _on_button_pressed():
	pass
