extends SubmenuArea


@export var console: Console


func trigger() -> void :
	if not ShopConsolePower.on:
		return
	if not can_interact:
		return

	super ()

	if console.focused:
		return

	shop.stop_voiceline()

	console.focused = true
	console.other_sounds.volume_linear = 1.0
	console.music_fader.play(&"fade_in")

	var carts: Control = console.get_node_or_null(^"%Cartridges")
	if carts:
		carts.grab_focus.call_deferred()
