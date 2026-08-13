@abstract extends RefCounted
class_name SpriteImporter


func get_format_name() -> StringName:
	return ""


func get_importer_data_class() -> String:
	return ""


func needs_atlas_path() -> bool:
	return true


func get_texture_extensions() -> PackedStringArray:
	return [".png", ".webp", ".tga", ".bmp", ".jpg", ".jpeg", ".svg"]


func get_atlas_extension() -> String:
	return ""


func should_check_dir() -> bool:
	return true
