extends VisibleOnScreenNotifier3D

@export var is_accessible: bool = true:
	set(value):
		if is_accessible == value:
			return

		is_accessible = value
		if is_accessible:
			if _is_visible:
				enable_viewport()
			else:
				disable_viewport()

@export var sub_viewport: SubViewport

var _is_visible: bool

func _ready() -> void :
	screen_entered.connect(enable_viewport)
	screen_exited.connect(disable_viewport)

func enable_viewport() -> void :
	_is_visible = true
	if !is_accessible:
		return

	sub_viewport.set_update_mode(SubViewport.UPDATE_ALWAYS)

func disable_viewport() -> void :
	_is_visible = false
	if !is_accessible:
		return

	sub_viewport.set_update_mode(SubViewport.UPDATE_DISABLED)
