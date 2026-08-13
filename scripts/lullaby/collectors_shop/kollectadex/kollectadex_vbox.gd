@tool
extends VBoxContainer

@export var pokedex_base: Control

func _ready() -> void :
	if Engine.is_editor_hint():
		EditorInterface.get_selection().connect("selection_changed", _entry_selected_in_editor)
	connect("child_order_changed", change_child_index)

func _enter_tree() -> void :
	change_child_index()

func change_child_index() -> void :
	for child: Node in get_children():
		if child is Control and child.index != null:
			child.index = child.get_index() + 1

func _entry_selected_in_editor():
	var selected_nodes: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.size() != 1 or selected_nodes.is_empty():
		return

	var selected_node: Node = selected_nodes[0]
	if selected_node is KollectadexEntry:
		selected_node.grab_focus()
		pokedex_base.change_dex(selected_node)
