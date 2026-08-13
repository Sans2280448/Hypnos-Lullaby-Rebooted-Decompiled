extends Control

enum AudioBus
{
	MASTER = LullabySettings.MASTER_VOLUME_BUS, 
	MUSIC = LullabySettings.MUSIC_VOLUME_BUS, 
	SOUND_EFFECTS = LullabySettings.SOUND_EFFECTS_VOLUME_BUS, 
	VOCALS = LullabySettings.VOCALS_VOLUME_BUS
}

@export var bus: AudioBus = AudioBus.MASTER

@export var slider: Slider
@export var percentage: Label

func _ready() -> void :
	var value: float = AudioServer.get_bus_volume_linear(int(bus))

	slider.set_value_no_signal(value)
	percentage.text = str(floori(value * 100.0)) + "%"

	if not slider.value_changed.is_connected(_on_value_changed):
		slider.value_changed.connect(_on_value_changed)

func _on_value_changed(value: float) -> void :
	match bus:
		AudioBus.MASTER:
			Settings.audio_master_volume = value
		AudioBus.MUSIC:
			Settings.audio_music_volume = value
		AudioBus.SOUND_EFFECTS:
			Settings.audio_sfx_volume = value
		AudioBus.VOCALS:
			Settings.audio_vox_volume = value

	percentage.text = str(floori(value * 100.0)) + "%"
	AudioServer.set_bus_volume_linear(int(bus), value)
