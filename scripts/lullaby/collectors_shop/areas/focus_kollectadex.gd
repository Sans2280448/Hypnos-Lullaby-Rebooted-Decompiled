extends SubmenuArea


@export var kollectadex: Kollectadex


func trigger() -> void :
	super ()

	if kollectadex and not kollectadex.focused:
		shop.stop_voiceline()

		kollectadex.open()
