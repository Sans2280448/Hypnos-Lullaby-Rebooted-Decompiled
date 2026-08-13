@tool
extends Tree
class_name ImporterAnimationTree

@export var tab: ImporterTab
@export var clear_button: Button

@export_group("Icons")
@export var trash_icon: Texture2D
var anim_name_list: PackedStringArray

func recieve_sprite(sprite_data: ImporterSpriteData) -> void :
	if get_root() == null:
		var root: TreeItem = create_item()

	set_column_expand(0, false)
	clear_button.disabled = false

	var sprite: TreeItem = create_item(get_root())
	sprite.add_button(0, trash_icon, 0)

	sprite.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	sprite.set_text(0, sprite_data.texture.resource_path.get_basename())
	sprite.set_expand_right(0, true)
	sprite.set_metadata(0, sprite_data)

	for anim_name: String in sprite_data.animation_list:
		var anim: TreeItem = create_item(sprite)
		anim.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		anim.set_checked(0, true)
		anim.set_editable(0, true)
		anim.set_editable(1, true)
		anim.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
		anim.set_metadata(1, anim_name)

		if !anim_name_list.has(anim_name):
			anim_name_list.append(anim_name)
		else:
			anim_name += " (merged)"


		anim.set_text(1, anim_name)

func import_tree() -> void :
	if tab == null:
		printerr("ImporterTab not set in exported variables.")
		return

	if get_root() == null:
		printerr("Animation Tree is empty.")
		return

	var disabled_anims: Array[String]
	var sprite_list: Array[ImporterSpriteData]

	for sprite: TreeItem in get_root().get_children():
		var sprite_data: ImporterSpriteData = sprite.get_metadata(0)
		if sprite_data is not ImporterSpriteData or sprite_data == null:
			printerr("Could not get sprite data.")
			return

		var repeated_sprite: bool = false
		for sprite_in_list: ImporterSpriteData in sprite_list:
			if sprite_in_list.atlas_path == sprite_data.atlas_path:
				repeated_sprite = true
				printerr("Skipping duplicated sprite: " + sprite_data.atlas_path.get_basename())

		if repeated_sprite:
			continue

		for anim: TreeItem in sprite.get_children():
			var anim_alias: String = anim.get_text(1)
			var anim_name: String = anim.get_metadata(1)

			if anim_name != anim_alias:
				sprite_data.anim_aliases.set(anim_name, anim_alias)

			if anim.is_checked(0):
				continue

			disabled_anims.append(anim_alias)
		sprite_list.append(sprite_data)

	var imported_sprite_frames: SpriteFrames = tab.importer.convert_sprite(sprite_list, disabled_anims)

	var save_dialog: ConfirmationDialog = tab._make_file_dialog()
	save_dialog.title = "Save SpriteFrames"
	save_dialog.file_mode = EditorFileDialog.FileMode.FILE_MODE_SAVE_FILE
	save_dialog.filters = ["*.tres ; Text-based Resource", "*.res ; Compressed Binary Resource"]
	save_dialog.current_dir = sprite_list[0].texture.resource_path.get_base_dir()

	save_dialog.disconnect("file_selected", tab.file_selected)

	save_dialog.connect("file_selected", func(path: String):
		if path.get_extension() == "res":
			ResourceSaver.save(imported_sprite_frames, path, ResourceSaver.FLAG_COMPRESS)
		elif path.get_extension() == "tres":
			ResourceSaver.save(imported_sprite_frames, path, ResourceSaver.FLAG_NONE)
		else:
			printerr("Invalid sprite save extension/path.")
		)
	add_child(save_dialog)
	save_dialog.popup_centered(Vector2i(768, 768) if Engine.is_editor_hint() else Vector2i(768, 512))

func item_button_clicked(item: TreeItem, column: int, id: int, mouse_bttn_idx: int):
	var sprite_data: ImporterSpriteData = item.get_metadata(0)
	match id:
		0:
			if sprite_data != null:
				print("Removed sprite: " + sprite_data.atlas_path.get_basename())

			for anim: TreeItem in item.get_children():
				anim_name_list.erase(anim.get_text(1))
			item.free()

func item_edited() -> void :
	pass

func clear_tree() -> void :
	for sprite: TreeItem in get_root().get_children():
		sprite.free()
	anim_name_list.clear()
	clear_button.disabled = true
