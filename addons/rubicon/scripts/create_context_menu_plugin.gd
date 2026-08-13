@tool
extends EditorContextMenuPlugin

signal popup_menu(paths: PackedStringArray)
const CREATE_CHARACTER_POPUP = preload("res://addons/rubicon/resources/editor/template_windows/make_character_dialog.tscn")


func _popup_menu(paths: PackedStringArray) -> void :
	popup_menu.emit(paths)

func _create_simple_character(path: String, char_name: String, type: StringName, sprite_frames_path: String = "", animation_library_path: String = "") -> void :
	if char_name.is_empty():
		printerr("Somehow you created a character with an empty name, even tho the UI does not make it possible... wow...")

	var template_path: String = ProjectSettings.get_setting("rubicon/defaults/character_template")
	var template_instance: Node
	if !template_path.is_empty() and ResourceLoader.exists(template_path):
		template_instance = load(template_path).instantiate()
		template_instance.name = char_name

	var scene: PackedScene = PackedScene.new()
	scene.pack(template_instance if template_instance != null and template_instance is RubiconCharacter else _make_character_tree(char_name, type, sprite_frames_path, animation_library_path))
	var scene_path: String = path + char_name + ".tscn"
	ResourceSaver.save(scene, scene_path)

func _make_character_tree(_name: String, type: StringName, sprite_frames_path: String = "", animation_library_path: String = "") -> Node:
	var root = ClassDB.instantiate(type)
	root.script = preload("res://addons/rubicon/scripts/scene/game/rubicon_character.gd")
	root.name = _name

	var sprite_anim_player: AnimationPlayer
	if !sprite_frames_path.is_empty():
		var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.name = &"Sprite"
		sprite.sprite_frames = load(sprite_frames_path)
		root.add_child(sprite)
		sprite.owner = root
		if !animation_library_path.is_empty():
			sprite_anim_player = AnimationPlayer.new()
			sprite_anim_player.name = &"SpriteAnimationPlayer"

			sprite_anim_player.add_animation_library(animation_library_path.get_file().get_basename(), load(animation_library_path))
			sprite.add_child(sprite_anim_player)
			sprite_anim_player.owner = root

	var root_anim_player: AnimationPlayer = AnimationPlayer.new()
	root_anim_player.name = "RootAnimationPlayer"
	root.add_child(root_anim_player)
	root_anim_player.owner = root
	root.animation_player = root_anim_player

	root_anim_player.add_animation_library(&"", AnimationLibrary.new())
	var library: AnimationLibrary = root_anim_player.get_animation_library(&"")
	library.add_animation(&"dance_idle", Animation.new())
	library.add_animation(&"sing_down", Animation.new())
	library.add_animation(&"sing_left", Animation.new())
	library.add_animation(&"sing_right", Animation.new())
	library.add_animation(&"sing_up", Animation.new())

	if sprite_anim_player != null:
		for anim_name: StringName in library.get_animation_list():
			var anim: Animation = library.get_animation(anim_name)
			var anim_track: int = anim.add_track(Animation.TYPE_ANIMATION)
			anim.track_set_path(anim_track, root.get_path_to(sprite_anim_player))
			anim.track_insert_key(anim_track, 0.0, &"")

	root.dancing_animations.append([&"dance_idle"])
	root.set(&"animations", {
		&"sing_down": &"sing_down", 
		&"sing_left": &"sing_left", 
		&"sing_right": &"sing_right", 
		&"sing_up": &"sing_up"
	})

	return root

func _create_level_scene() -> void :
	pass
