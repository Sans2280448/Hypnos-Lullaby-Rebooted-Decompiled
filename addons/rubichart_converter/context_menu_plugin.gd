@tool
extends EditorContextMenuPlugin

enum ChartType{
	INVALID, 
	CODENAME, 
	FUNKIN, 
	FANTASY, 
	VSLICE
}

const Converters: Dictionary[String, GDScript] = {
	"CODENAME": preload("res://addons/rubichart_converter/converters/codename.gd"), 
	"FUNKIN": preload("res://addons/rubichart_converter/converters/funkin.gd"), 
	"FANTASY": preload("res://addons/rubichart_converter/converters/fantasy.gd"), 
	"VSLICE": preload("res://addons/rubichart_converter/converters/vslice.gd")
}

const MetaSelector: PackedScene = preload("res://addons/rubichart_converter/converter_meta_selector.tscn")

var _chart_type: ChartType

func _popup_menu(paths: PackedStringArray) -> void :
	if paths.size() > 1:
		return

	if !paths[0].ends_with(".json"):
		return

	var chart_text: String = FileAccess.get_file_as_string(paths[0]).to_lower()
	var chart_parse: Dictionary = JSON.parse_string(chart_text)
	_chart_type = ChartType.INVALID

	if chart_parse.has("song"):
		_chart_type = ChartType.FUNKIN
	if chart_parse.has("codenamechart"):
		_chart_type = ChartType.CODENAME
	if chart_parse.has("generatedby"):
		_chart_type = ChartType.VSLICE
	if chart_parse.has("charactercharts"):
		_chart_type = ChartType.FANTASY

	if _chart_type == ChartType.INVALID:
		return

	var icon: Texture2D = EditorInterface.get_editor_theme().get_icon(&"New", &"EditorIcons")
	add_context_menu_item("Convert %s to RubiChart" % [ChartType.keys()[_chart_type]], _make_chart, icon)

func _make_chart(args: Array) -> void :
	var _args: Array[String] = []
	_args.append(args[0])
	var chart_type_string: String = ChartType.keys()[_chart_type]
	if Converters[chart_type_string] == null:
		return

	if !Converters[chart_type_string].needs_metadata():
		Converters[chart_type_string].convert_chart(_args)
		return

	var meta_selector: Window = MetaSelector.instantiate()
	meta_selector._chart_type = chart_type_string
	EditorInterface.get_base_control().add_child(meta_selector)
	meta_selector.connect(&"accepted", func(meta_path: String, skipped: bool):
		if !skipped and !meta_path.is_empty():
			_args.append(meta_path)
		elif meta_path.is_empty():
			return
		Converters[chart_type_string].convert_chart(_args)
		)
