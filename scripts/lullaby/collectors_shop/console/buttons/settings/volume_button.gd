extends IncrementalSettingsButton


@export var bus: StringName = &"Master"


func _ready() -> void :
	super ()

	Settings.volume_changed.connect(_on_volume_changed)


func _on_volume_changed(bus_: StringName, volume: float) -> void :
	if bus_ == bus:
		value = volume
		update_text()
