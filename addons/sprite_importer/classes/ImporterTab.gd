@tool
extends Control
class_name ImporterTab

@export var importer_script: GDScript
var importer: SpriteImporter

@export_group("Quick Import References", "quick_")
@export var quick_sprite_path: LineEdit
@export var quick_atlas_path: LineEdit
@export var quick_fps: SpinBox
@export var quick_check_dupped: CheckBox
@export var quick_loop: CheckBox
@export var quick_compress_output: CheckBox
@export var quick_use_frame_duration: CheckBox
@export var make_anim_library: CheckBox
@export var anim_tree: ImporterAnimationTree

var focused_line_edit: Node

func _ready() -> void :
	if importer_script == null:
		return
	importer = (importer_script).new() as SpriteImporter
	name = importer.get_format_name()
	var enabled_plugins = ProjectSettings.get_setting("editor_plugins/enabled")
	var has_spriteframe_keyframer = enabled_plugins.has("res://addons/spriteframes_keyframer/plugin.cfg")
	if has_spriteframe_keyframer:
		make_anim_library.disabled = false
		make_anim_library.text = "Make AnimationLibrary"
		make_anim_library.button_pressed = true

	if quick_sprite_path != null or quick_atlas_path != null and importer.needs_atlas_path():
		quick_sprite_path.connect("text_changed", autofill_atlas_path)
		quick_sprite_path.connect("text_submitted", autofill_atlas_path)

		quick_atlas_path.connect("text_changed", autofill_sprite_path)
		quick_atlas_path.connect("text_submitted", autofill_sprite_path)

func process_sprite() -> Array[ImporterSpriteData]:
	var sprite_list: Array[ImporterSpriteData]
	var sprite_name_list: PackedStringArray
	var path_is_directory: bool = quick_sprite_path.text.get_extension().is_empty()

	var class_list: Array[Dictionary] = ProjectSettings.get_global_class_list()
	var importer_data_dir: Dictionary = class_list.filter(filter_importer_data_class)[0]
	if importer_data_dir.is_empty():
		printerr("The importer data class in the " + importer.get_format_name() + " importer is invalid or does not extend ImporterSpriteData.")
		return []

	var importer_data_class = load(importer_data_dir["path"])

	if quick_sprite_path.text.is_empty():
		printerr("Provided sprite path is empty.")
		return []

	if path_is_directory:
		if !importer.should_check_dir():
			printerr("Provided path is a directory.")
			return []

		print("Provided path is a directory. Converting every sprite in it...")

		var folder_sprites: PackedStringArray = DirAccess.get_files_at(quick_sprite_path.text);

		for sprite: String in folder_sprites:
			sprite_name_list.append(quick_sprite_path.text + sprite)

	else:
		sprite_name_list.append(quick_sprite_path.text)

	for sprite: String in sprite_name_list:
		if !FileAccess.file_exists(sprite) or !importer.get_texture_extensions().has("." + sprite.get_extension()):
			if !path_is_directory:
				printerr("Path \"" + sprite + "\" doesn't appear to be a valid sprite type.")
			continue

		var texture: Texture2D = load(sprite)
		var atlas: String = sprite.get_basename() + importer.get_atlas_extension() if quick_atlas_path.text.is_empty() else quick_atlas_path.text

		print("Detected sprite with path: " + sprite + "\nDetected atlas with path: " + atlas)

		var sprite_data: ImporterSpriteData = importer_data_class.new()
		sprite_data.texture = texture
		sprite_data.atlas_path = atlas
		sprite_data.check_dupped = quick_check_dupped.button_pressed
		sprite_data.loop = quick_loop.button_pressed
		sprite_data.fps = quick_fps.value
		sprite_data.use_frame_duration = quick_use_frame_duration.button_pressed
		sprite_list.append(sprite_data)

	return sprite_list

func add_to_tree():
	var sprite_list: Array[ImporterSpriteData] = process_sprite()

	if sprite_list.is_empty():
		printerr("Couldn't add to tree. No sprites found with the given path.")
		return

	for sprite_data: ImporterSpriteData in sprite_list:
		anim_tree.recieve_sprite(sprite_data)

	quick_sprite_path.text = ""
	quick_atlas_path.text = ""

func on_quick_import() -> void :
	var sprite_list: Array[ImporterSpriteData] = process_sprite()

	if sprite_list.is_empty():
		printerr("Couldn't import. No sprites found with the given path.")
		return




	for sprite_data: ImporterSpriteData in sprite_list:
		var array: Array[ImporterSpriteData] = [sprite_data]
		var imported_sprite_frames: SpriteFrames = importer.convert_sprite(array)
		if imported_sprite_frames == null:
			printerr("Error found importing sprite. Result equals null.")
			return

		var save_path: String = sprite_data.texture.resource_path.get_basename() + (".tres" if !quick_compress_output.pressed else ".res")

		ResourceSaver.save(imported_sprite_frames, save_path, ResourceSaver.FLAG_NONE if !quick_compress_output.pressed else ResourceSaver.FLAG_COMPRESS)
		if ResourceLoader.exists(save_path):
			print("SpriteFrame succesfully created at path: " + save_path)

			if make_anim_library:
				var class_list: Array[Dictionary] = ProjectSettings.get_global_class_list()
				var keyframer_data: Dictionary = class_list.filter(filter_keyframer_data_class)[0]
				if keyframer_data.is_empty():
					printerr("Attempted to create AnimationLibrary, but SpriteFramesKeyframer wasn't found")
					return

				var keyframer = load(keyframer_data["path"])
				keyframer._make_library([save_path])


func _make_file_dialog() -> ConfirmationDialog:
	var file_dialog: ConfirmationDialog

	if Engine.is_editor_hint():
		file_dialog = EditorFileDialog.new()
	else:
		file_dialog = FileDialog.new()

	file_dialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_ANY
	var screen_size: Vector2 = DisplayServer.screen_get_size()
	file_dialog.size = Vector2(screen_size.x / 2, screen_size.y / 1.5)
	file_dialog.initial_position = Window.WindowInitialPosition.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	file_dialog.connect("dir_selected", dir_selected)
	file_dialog.connect("file_selected", file_selected)

	var filters: PackedStringArray = importer.get_texture_extensions() + PackedStringArray([importer.get_atlas_extension()])
	for i in filters.size():
		var filter: String = filters[i]
		filter = "*" + filter
		filters[i] = filter
	file_dialog.filters = filters

	return file_dialog

func _exit_tree() -> void :




	if quick_sprite_path != null and quick_atlas_path != null and importer.needs_atlas_path():
		quick_sprite_path.disconnect("text_changed", autofill_atlas_path)
		quick_sprite_path.disconnect("text_submitted", autofill_atlas_path)

func folder_button(source: Button, _focused_line_edit: NodePath) -> void :
	focused_line_edit = source.get_node(_focused_line_edit)

	var file_dialog: ConfirmationDialog = _make_file_dialog()
	file_dialog.title = "Select a spritesheet"
	add_child(file_dialog)
	file_dialog.popup_centered()
	file_dialog.connect("visibility_changed", func(): file_dialog.queue_free())

func file_selected(path: String) -> void :
	var line_edit = focused_line_edit
	if line_edit is not LineEdit or line_edit == null:
		return
	var is_sprite_path = line_edit.get_meta("is_sprite_path", false)

	var valid_sprite_extension = find_closest_sprite_extension(path)

	if is_sprite_path:
		var texture_extensions: PackedStringArray = importer.get_texture_extensions()
		if !texture_extensions.has(path.get_extension()):
			path = path.get_basename() + valid_sprite_extension
			print(path)

		autofill_atlas_path(path)
	else:
		if "." + path.get_extension() != importer.get_atlas_extension():
			var atlas_path_predict: String = path.get_basename() + importer.get_atlas_extension()
			if FileAccess.file_exists(atlas_path_predict):
				path = atlas_path_predict

		autofill_sprite_path(path)

	line_edit.text = path;

func dir_selected(path: String) -> void :
	if !path.ends_with("/"):
		path += "/"

	var line_edit = focused_line_edit
	if line_edit is LineEdit and line_edit != null:
		line_edit.text = path;
	else:
		printerr("Node connected is not a LinePath or is null.")
	autofill_atlas_path(path)

func find_closest_sprite_extension(path: String):
	var texture_extensions: PackedStringArray = importer.get_texture_extensions()
	for tex_extension: String in texture_extensions:
		if FileAccess.file_exists(path.get_basename() + tex_extension):
			return tex_extension

func autofill_sprite_path(new_path: String):
	if !new_path.get_extension().is_empty() and find_closest_sprite_extension(new_path) != null:
		var sprite_path_predict: String = new_path.get_basename() + find_closest_sprite_extension(new_path)

		if FileAccess.file_exists(sprite_path_predict):
			quick_sprite_path.text = sprite_path_predict

func autofill_atlas_path(new_path: String):
	if importer.get_texture_extensions().has("." + new_path.get_extension()):
		var atlas_path_predict: String = new_path.get_basename() + importer.get_atlas_extension()

		if FileAccess.file_exists(atlas_path_predict):
			quick_atlas_path.text = atlas_path_predict

func filter_importer_data_class(_class: Dictionary) -> bool:
	if _class["base"] != "ImporterSpriteData":
		return false

	return _class["class"] == importer.get_importer_data_class()

func filter_keyframer_data_class(_class: Dictionary) -> bool:
	return _class["class"] == "SpriteFramesKeyframer"
