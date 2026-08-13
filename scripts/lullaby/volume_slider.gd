extends Node

@export var bar_container: Control
@export var timer: Timer
@export var animation_player: AnimationPlayer

@export var fill_color: Color
@export var disabled_color: Color
@export var empty_color: Color

@export var volume_down: AudioStreamPlayer
@export var volume_up: AudioStreamPlayer

@export var stupid_ass_jumpscare: TextureRect

var _jumpscare_counter: int = 0

func _ready() -> void :
	Settings.volume_changed.connect(_on_volume_changed)

func _input(event: InputEvent) -> void :
	if event.is_action_pressed("volume_up"):
		volume_up.play()
		change_volume(0.1)
	if event.is_action_pressed("volume_down"):
		volume_down.play()
		change_volume(-0.1)
	if event.is_action_pressed("volume_mute"):
		toggle_mute()

func change_volume(change: float = 0) -> void :
	if Settings.audio_master_volume + change >= 1.2:
		_jumpscare_counter += 1

	if not AudioServer.is_bus_mute(LullabySettings.MASTER_VOLUME_BUS):
		Settings.audio_master_volume = clampf(Settings.audio_master_volume + change, 0, 1.2)
		AudioServer.set_bus_volume_linear(LullabySettings.MASTER_VOLUME_BUS, Settings.audio_master_volume)
	else:
		toggle_mute()

	if _jumpscare_counter >= 30:
		stupid_ass_jumpscare.visible = true
		AudioServer.set_bus_volume_linear(LullabySettings.MASTER_VOLUME_BUS, 0)
		AudioServer.set_bus_mute(LullabySettings.MASTER_VOLUME_BUS, true)

	update_bars()

	if !animation_player.assigned_animation.contains("in"):
		if animation_player.is_playing():
			animation_player.play(&"in_immediate")
		else:
			animation_player.play(&"in")

	if !timer.is_stopped():
		timer.stop()
	timer.start()
	await timer.timeout

	if Settings.audio_master_volume >= 0:
		AudioServer.set_bus_volume_linear(LullabySettings.MASTER_VOLUME_BUS, Settings.audio_master_volume)
		AudioServer.set_bus_mute(LullabySettings.MASTER_VOLUME_BUS, false)
		update_bars()

	Settings.save()

	_jumpscare_counter = 0
	stupid_ass_jumpscare.visible = false

	animation_player.stop()
	animation_player.play(&"out")

func toggle_mute() -> void :
	var is_muted: bool = AudioServer.is_bus_mute(LullabySettings.MASTER_VOLUME_BUS)
	AudioServer.set_bus_mute(LullabySettings.MASTER_VOLUME_BUS, !is_muted)

	update_bars()

	if !animation_player.assigned_animation.contains("in"):
		if animation_player.is_playing():
			animation_player.play(&"in_immediate")
			return
		else:
			animation_player.play(&"in")

	if !timer.is_stopped():
		timer.stop()
	timer.start()
	await timer.timeout

	animation_player.stop()
	animation_player.play(&"out")

func update_bars() -> void :
	if AudioServer.is_bus_mute(LullabySettings.MASTER_VOLUME_BUS):
		for bar: ProgressBar in bar_container.get_children():
			bar.modulate.a = 0.4

		return

	var volume_rounded: int = roundi(Settings.audio_master_volume * 100.0)
	var incomplete_index: int = floori(volume_rounded / 10.0)
	for i in bar_container.get_child_count():
		var bar: ProgressBar = bar_container.get_child(i)
		bar.modulate.a = 1.0

		if i < incomplete_index:
			bar.value = 10.0
		elif i == incomplete_index:
			bar.value = volume_rounded % 10
		elif i > incomplete_index:
			bar.value = 0.0

func _on_volume_changed(_bus: StringName, _volume: int) -> void :
	update_bars()
