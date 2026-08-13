extends CanvasLayer

var _screen: Control
var _hat: Label
var _text: Label

signal confirmed

func _ready() -> void :
	layer = RenderingServer.CANVAS_LAYER_MAX
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_warning(message: String, err: Error) -> void :
	get_tree().paused = true

	_create_screen(Color.BLUE)
	_text.text = message
	_text.text += "\n\nError Code: 0x%08x" % err
	_text.text += "\n\nPress the ACCEPT button to acknowledge and resume.\n\nFor more assistance, contact the Cabinet of Novelties developers.\nhttps://www.cabinetofnovelties.com/contact.html"

	await confirmed

	_destroy_screen()
	get_tree().paused = false

func show_error(message: String, err: Error) -> void :
	print("STOPPING GAME")

	for node in get_tree().root.get_children():
		if node != self:
			node.queue_free()

	_create_screen(Color.hex(3206619647))
	_text.text = "A serious error has occured.\n\n"
	_text.text += message
	_text.text += "\n\nError Code: 0x%08x" % err
	_text.text += "\n\nThe game has been shut down to prevent further damage.\n\nPlease contact the Cabinet of Novelties developers for assistance.\nhttps://www.cabinetofnovelties.com/contact.html"

func _create_screen(color: Color) -> void :
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	Engine.max_fps = 1

	_screen = ColorRect.new()
	add_child(_screen)

	_screen.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT, true)
	_screen.color = color

	_text = Label.new()
	_text.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
	_text.offset_left = -550
	_text.offset_right = 550
	_text.offset_top = -300
	_text.offset_bottom = 300

	var font: SystemFont = SystemFont.new()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.font_names = ["monospace"]

	_text.label_settings = LabelSettings.new()
	_text.label_settings.font = font
	_text.label_settings.font_size = 32
	_text.label_settings.shadow_color = Color.hex(159)
	_text.label_settings.shadow_offset = Vector2(2, 2)
	_screen.add_child(_text)

	_hat = Label.new()
	_hat.label_settings = _text.label_settings.duplicate()
	_hat.label_settings.line_spacing = -16
	_hat.text = "       #######      \n    ############    \n    ############    \n     ##########     \n     ##########     \n      ########      \n####################\n ################## \n   ###############  \n     ##########     "










	_screen.add_child(_hat)

func _destroy_screen() -> void :
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	Engine.max_fps = Settings.display_target_fps
	_screen.queue_free()

func _input(event: InputEvent) -> void :
	if not _screen:
		if event is InputEventKey and event.alt_pressed:
			if event.keycode == Key.KEY_F11:
				show_warning("This warning was intentionally done by the end-user. Nothing to report.", OK)

			if event.keycode == Key.KEY_F12:
				show_error("This crash was intentionally done by the end-user. Nothing to report.", OK)

		return

	if event.is_action_pressed(&"ui_accept"):
		confirmed.emit()
