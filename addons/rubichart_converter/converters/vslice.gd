static func get_new_parameters() -> Dictionary[String, Variant]:
	return Dictionary()

static func needs_metadata() -> bool:
	return true

static func convert_chart(args: Array[String]) -> void :
	var file_path: String = args[0]
