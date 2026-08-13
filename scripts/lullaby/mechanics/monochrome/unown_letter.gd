@tool
class_name UnownLetter extends Node2D

@export var character: String:
	get:
		return _character
	set(val):
		if val.length() > 1:
			printerr("[ERROR] Character must be one letter or lower!")
			return

		val = val.to_upper()

		if _character != val:
			if not val.is_empty():
				animator_letter.play(animation_letter % val)
			else:
				animator_letter.play(animation_letter_none)

			animator_letter.seek(0.0)

		_character = val

@export_group("Animations", "animation_")
@export var animation_letter: String = "Unown%s Act"
@export var animation_letter_none: String = "UnownNone"
@export var animation_enter: StringName = &"enter"
@export var animation_active: StringName = &"active"
@export var animation_fail: StringName = &"failure"
@export var animation_success: StringName = &"success"
@export var animation_exit: StringName = &"exit"

@export_group("Animators", "animator_")
@export var animator_main: AnimationPlayer
@export var animator_letter: AnimationPlayer

signal arrived_on_screen

var _character: String = ""

func enter(delay: float) -> void :
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout

	visible = true
	animator_main.play(animation_enter)
	animator_letter.seek(0.0)

	await animator_main.animation_finished

	arrived_on_screen.emit()

func activate() -> void :
	if animator_main.current_animation == animation_active:
		return

	animator_main.play(animation_active)
	animator_main.seek(0.0)

func succeed() -> void :
	if animator_main.current_animation == animation_success or animator_main.assigned_animation == animation_success:
		return

	animator_main.play(animation_success)

func fail() -> void :
	animator_main.play(animation_fail)
	animator_main.seek(0.0)

func exit(delay: float) -> void :
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout

	animator_main.play(animation_exit)
	animator_main.seek(0.0)
