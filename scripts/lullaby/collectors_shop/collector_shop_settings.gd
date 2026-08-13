class_name CollectorShopSettings extends Node

@export var use_user_settings_on_runtime: bool = true

@export_group("Settings", "settings_")
@export var settings_post_processing: LullabySettings.PostProcessing = LullabySettings.PostProcessing.HIGH
@export var settings_ssao: bool = true
@export var settings_ssil: bool = true

func _ready() -> void :
	if Engine.is_editor_hint() or not use_user_settings_on_runtime:
		return

	_update()

	Settings.applied.connect(_update)

func _update() -> void :
	settings_post_processing = Settings.graphics_post_processing
	settings_ssao = Settings.graphics_ssao
	settings_ssil = Settings.graphics_ssil
