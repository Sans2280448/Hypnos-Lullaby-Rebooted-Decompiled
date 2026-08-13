extends Control

@export var option_button: OptionButton
@export var root: Window

func _ready() -> void :
	option_button.selected = int(get_preset_idx())

	if not option_button.item_selected.is_connected(_on_preset_selected):
		option_button.item_selected.connect(_on_preset_selected)

func _on_preset_selected(index: int) -> void :
	match index:
		0:
			pass
		1:
			LullabySettings.PRESET_LOW.apply(Settings)
		2:
			LullabySettings.PRESET_MEDIUM.apply(Settings)
		3:
			LullabySettings.PRESET_HIGH.apply(Settings)

	if root:
		root.reload_settings()

func get_preset_idx() -> int:
	var preset: LullabyQualityPreset = Settings.get_quality_preset()
	if not preset:
		return 0

	if preset == LullabySettings.PRESET_LOW:
		return 1
	if preset == LullabySettings.PRESET_MEDIUM:
		return 2
	if preset == LullabySettings.PRESET_HIGH:
		return 3

	return 0
