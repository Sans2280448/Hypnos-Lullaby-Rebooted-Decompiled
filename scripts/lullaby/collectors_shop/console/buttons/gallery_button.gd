extends ConsoleHomeButton

func _input(event: InputEvent) -> void :
	if console.booting:
		return

	if event.is_action_released(&"ui_accept") and focused:
		focused = false
		icon_animation_player.play(select_animation)
		home_container.disable_icons.emit()
		console.play_sound.emit("sfx_soulroom_select_alt")
		icon_animation_player.animation_finished.connect( func(anim: StringName):
			if anim == "Select_48f":
				OS.shell_open("https://cabinetofnovelties.com/gallery.html")
				home_container.enable_icons.emit()
		, CONNECT_ONE_SHOT)
