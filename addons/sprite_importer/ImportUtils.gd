@tool
extends Node
class_name ImportUtils

static var addon_path: String
static var format_importers: Dictionary[String, String]

static func file_type_to_importer(type: String) -> SpriteImporter:
	if format_importers.keys().has(type):
		format_importers[type]

	return null
