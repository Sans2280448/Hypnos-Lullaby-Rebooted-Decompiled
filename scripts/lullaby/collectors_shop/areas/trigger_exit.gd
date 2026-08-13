extends TriggerArea3D

@export var shop: CollectorShop
@export var camera_positions: AnimationPlayer
@export var cine_bars: AnimationPlayer
@export var dialogue: CollectorDialogue

@export var override_quit: bool = true:
	set(value):
		override_quit = value
		get_tree().auto_accept_quit = !override_quit
		return value

func _ready() -> void :
	get_tree().auto_accept_quit = false

func _notification(what: int) -> void :
	if !override_quit: return

	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _closing_game:
			get_tree().quit()
		else:
			_closing_game = true
			trigger()

func _exit_tree() -> void :
	get_tree().auto_accept_quit = true

var _closing_game = false
var _leaving: bool = false

func trigger() -> void :
	if not can_interact:
		return

	shop.state = shop.ShopStates.BUSY;
	shop.stop_voiceline()

	if not _closing_game:
		camera_positions.play(&"byebye")

		cine_bars.stop()
		cine_bars.play(&"IN")

		dialogue.play_move_up()

	shop.play_voiceline_group("byebye")

	_leaving = true


func _on_collector_shop_voice_entry_finished() -> void :
	if _leaving:
		if _closing_game:
			get_tree().quit()
		else:
			GameIntro.skip_intro = true
			SceneChanger.change_to("uid://bj63tbt25fbyg", &"hypno")
