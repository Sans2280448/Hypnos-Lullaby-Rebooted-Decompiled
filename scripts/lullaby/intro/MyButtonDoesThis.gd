extends Button

var helpmeimgettingflacid: Tween

func _ready() -> void :
	focus_entered.connect(checkmeoutdawg)
	mouse_entered.connect(checkmedoubletime)
	focus_exited.connect(STOPLOOKINGATME)
	mouse_exited.connect(STOPLOOKINGATMEYOUSICKO)
	pressed.connect(boopedthatsnoot)
	button_down.connect(boopedthatsnoot)
	button_up.connect(unboopiguess)

func checkmeoutdawg():

	print("fartbutt")
	if helpmeimgettingflacid != null:
		print("hi")
		helpmeimgettingflacid.kill()
	helpmeimgettingflacid = get_tree().create_tween()
	helpmeimgettingflacid.tween_property(self, "scale", Vector2(1.03, 1.03), 0.1)

func checkmedoubletime():

	grab_focus()

func STOPLOOKINGATME():

	print("im getting flacid")
	if helpmeimgettingflacid != null:
		print("im tiny now!")
		helpmeimgettingflacid.kill()
	helpmeimgettingflacid = get_tree().create_tween()
	helpmeimgettingflacid.tween_property(self, "scale", Vector2(1, 1), 0.1)

func STOPLOOKINGATMEYOUSICKO():

	release_focus()

func boopedthatsnoot():

	print("FUCK MAN OUUUCHHH")
	if helpmeimgettingflacid != null:
		helpmeimgettingflacid.kill()
	helpmeimgettingflacid = get_tree().create_tween()
	helpmeimgettingflacid.tween_property(self, "scale", Vector2(0.99, 0.99), 0.08)

func unboopiguess():
	if helpmeimgettingflacid != null:
		helpmeimgettingflacid.kill()
	helpmeimgettingflacid = get_tree().create_tween()
	helpmeimgettingflacid.tween_property(self, "scale", Vector2(1.03, 1.03), 0.09).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)


func _on_mouse_entered() -> void :
	pass
