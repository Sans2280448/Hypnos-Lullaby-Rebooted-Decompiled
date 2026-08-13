@tool
extends Control

@export var root: ConfirmationDialog
var item_selections: Array[NodePath]

func set_item(path: NodePath, value: bool) -> void :
	if !item_selections.has(path):
		item_selections.append(path)

	for item: NodePath in item_selections:
		var node = get_node(item_selections[item_selections.find(item)])
		if item == path and value:
			node._selected = true
			root._selected_type = node.name
			continue

		node._selected = false
