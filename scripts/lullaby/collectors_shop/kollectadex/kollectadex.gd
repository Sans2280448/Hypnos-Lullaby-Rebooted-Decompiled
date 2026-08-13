@tool
class_name Kollectadex
extends Control


const SIDE_ORIGINAL_X: float = 848
const SIDE_TWEEN_SPD: float = 0.25

@export var sequences: ShopSequences
@export var focus_left_area: FocusArea3D
@export var kollectadex_anims: AnimationPlayer

@export var inputs_container: Control

@export var character_sprite: TextureRect

@export var character_name: Label
@export var character_subtitle: Label

@export var collection_label: Label

@export_group("Sounds")

@export var music: AudioStreamPlayer
@export var switch_sound: AudioStreamPlayer
@export var select_sound: AudioStreamPlayer
@export var select_failed_sound: AudioStreamPlayer
@export var close_sound: AudioStreamPlayer

@export_group("Side Panel")

@export var side_panel: TextureRect

@export var side_name: Label
@export var side_info: Label
@export var side_collectors_info: Label

var seen_on: String = "???"

var cur_index: int = 0:
	set(v):
		if cur_index != v:
			cur_index = v

var can_move: bool = true

var collected: int = 0
var collected_max: int = 0

var music_tween: Tween

var focused: bool = false;

func _ready() -> void :
	if Engine.is_editor_hint():
		return

	collected_max = 0

	for child in inputs_container.get_children():
		if child.unlocked:
			collected += 1

		collected_max += 1

		if not child.change_focus.is_connected(change_dex):
			child.change_focus.connect(change_dex)

	setup_from_save()

func open():
	focused = true

	can_move = true
	setup_from_save()

func close():
	if music_tween and music_tween.is_running():
		music_tween.custom_step(9999)
		music_tween.kill()

	music_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	music_tween.tween_property(music, ^"volume_linear", 0.0, 1.0)
	music_tween.finished.connect( func stop(): music.stop(), CONNECT_ONE_SHOT)

	focus_left_area.can_interact = true
	focus_left_area.register_trigger()

	if sequences:
		sequences.animation_player.play(&"focus_left")

	if kollectadex_anims:
		kollectadex_anims.play(&"kollectadex_animations/return")

	if close_sound:
		close_sound.play()

	focused = false

func _input(event: InputEvent) -> void :
	if Engine.is_editor_hint():
		return
	if event.is_echo() or not event.is_pressed():
		return

	if not focused:
		return

	if event.is_action(&"ui_cancel"):
		if not can_move:
			inspect()
		else:
			close()

	if event.is_action(&"ui_accept"):
		if not inputs_container.get_child(cur_index).unlocked:
			select_failed_sound.play()
		elif can_move:
			inspect()

	for c: Node in inputs_container.get_children():
		c.focus_mode = Control.FOCUS_ALL if can_move else Control.FOCUS_NONE


func inspect():
	if can_move:
		select_sound.play()

	can_move = not can_move
	var t: = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(
		side_panel, 
		^"position:x", 
		SIDE_ORIGINAL_X if can_move
		else 0.0, 
		SIDE_TWEEN_SPD
	);
	if can_move:
		await get_tree().create_timer(SIDE_TWEEN_SPD).timeout
		inputs_container.get_child(cur_index).focus_mode = Control.FOCUS_ALL
		inputs_container.get_child(cur_index).grab_focus();

func setup_from_save() -> void :
	cur_index = 0
	inputs_container.get_child(cur_index).grab_focus()



func change_dex(entry: KollectadexEntry, sound: bool = true) -> void :
	if sound and cur_index != entry.index - 1:
		switch_sound.play()

	cur_index = entry.index - 1

	character_sprite.texture = load(entry.character_image.resource_path)
	character_sprite.custom_minimum_size = character_sprite.texture.get_size() * 5
	character_name.text = entry.character_name
	character_subtitle.text = entry.character_subtitle

	side_name.text = entry.character_name;
	side_info.text = entry.character_desc;

	update_collection_info(entry)

	if Engine.is_editor_hint():
		character_sprite.modulate = Color.WHITE
		return

	if entry.unlocked:
		character_sprite.modulate = Color.WHITE
		seen_on = entry.seen_on
	else:
		character_sprite.modulate = Color.BLACK
		seen_on = "???"



func update_collection_info(entry: KollectadexEntry) -> void :
	collection_label.text = "Seen On: %s\nCollected: %03d / %03d" % [
		seen_on, 
		collected, 
		collected_max, 
	]
