extends Control

@export var song_forwarder: Dictionary[int, String] = {}
@export var song_selector: OptionButton
@export var song_requester: Button

@export_file("*.tscn") var intro_scene_path: String
@export_file("*.tscn") var shop_scene_path: String
@export_file("*.tscn") var warning_scene_path: String
@export_file("*.tscn") var benchmark_scene_path: String

func _ready() -> void :
	song_requester.pressed.connect(_on_requested_play)

func _on_requested_play() -> void :
	var is_chimera: bool = song_selector.get_item_text(song_selector.selected).to_lower() == "chimera"

	SceneChanger.change_to(song_forwarder[song_selector.selected], &"hypno", is_chimera)

func _on_requested_intro() -> void :
	SceneChanger.change_to(intro_scene_path, &"hypno")

func _on_requested_shop() -> void :
	SceneChanger.change_to(shop_scene_path, &"hypno", true)

func _on_requested_warning() -> void :
	SceneChanger.change_to(warning_scene_path, &"default")

func _on_requested_benchmark(precache: bool) -> void :
	ShopBenchmark.precache_shaders = precache
	SceneChanger.change_to(benchmark_scene_path, &"hypno")

func _on_request_settings() -> void :
	Debugger.settings.open()

func _reset_save() -> void :
	SaveData.reset()
