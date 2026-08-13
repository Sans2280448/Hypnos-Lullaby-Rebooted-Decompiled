class_name GBCreditsMenu extends Control

@export var opened: bool = false

@export var reference_credits_menu: GBPauseMenu
@export var reference_title_text: Label
@export var reference_description_text: Label
@export var reference_confirm: AudioStreamPlayer

signal exited

func open() -> void :
	opened = true

	if reference_credits_menu.level != null:
		var meta: RubiconLevelMetadata = reference_credits_menu.level.metadata
		reference_title_text.text = meta.title
		reference_description_text.text = meta.description

func exit() -> void :
	reference_confirm.play()
	visible = false
	opened = false

	exited.emit()
