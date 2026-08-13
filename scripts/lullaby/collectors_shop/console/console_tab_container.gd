extends TabContainer

@export var bind_label: Label
@export var console_root: Console
@export var header_label: Label
@export var animplayer: AnimationPlayer
var _last_tab_idx: int
var tabs_array = [
	"Home", 
	"Credits", 
	"Settings", 
	"Cartridges", 
	"Training"
]


func _on_tab_changed(tab: int) -> void :
	var new_tab: ConsoleTab = get_child(tab)
	var last_tab: ConsoleTab = get_child(_last_tab_idx)
	last_tab.save_last_focus()
	console_root.in_home = tab == 0

	header_label.text = tabs_array[tab]

	if tab == 0:
		new_tab.enable_icons.emit()
	else:
		animplayer.play("header_in")

	if new_tab.default_focus:
		new_tab.default_focus.grab_focus()

	if new_tab._last_focus:
		new_tab._last_focus.grab_focus()
		return



func change_tab(tab: int) -> void :
	modulate.a = 1
	if current_tab == tab:
		return

	if current_tab != 0:
		animplayer.play("header_out")

	_last_tab_idx = current_tab
	var tween = create_tween()
	await tween.tween_property(self, "modulate:a", 0.0, 0.2).finished
	tween.kill()
	tween = create_tween()
	self.current_tab = tab
	await tween.tween_property(self, "modulate:a", 1.0, 0.2).finished
	tween.kill()
