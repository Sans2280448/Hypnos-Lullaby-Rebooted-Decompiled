extends Window

func open() -> void :
	reload_settings()

	var dpi_rescale: float = 0.5 * (DisplayServer.screen_get_dpi(-1) / 96.0)
	size = Vector2i(floori(1000 * dpi_rescale), floor(900 * dpi_rescale))

	visible = true

func close() -> void :
	visible = false

func save() -> void :
	Settings.save()

func reload() -> void :
	Settings.load_from()
	reload_settings()

func apply() -> void :
	Settings.apply_settings()
	reload_settings()
	grab_focus()

func reload_settings() -> void :
	var node_stack: Array[Node] = [self]
	while node_stack.size() > 0:
		var current_node: Node = node_stack.pop_back()
		if current_node.has_method(&"_ready"):
			current_node._ready()

		node_stack.append_array(current_node.get_children())
