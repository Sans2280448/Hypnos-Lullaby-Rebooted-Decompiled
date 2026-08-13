extends ListButton

@export var resolution_button: ListButton
@export var next_node: Button

func _input(event: InputEvent) -> void :
	super._input(event)

	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		if index == 0:
			resolution_button.add_theme_color_override(&"font_color", Color.WHITE)
			focus_neighbor_bottom = resolution_button.get_path()
			next_node.focus_neighbor_top = resolution_button.get_path()
		else:
			resolution_button.add_theme_color_override(&"font_color", Color.DIM_GRAY)
			focus_neighbor_bottom = next_node.get_path()
			next_node.focus_neighbor_top = self.get_path()
