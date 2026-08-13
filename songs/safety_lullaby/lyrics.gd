@tool
extends Node2D

@onready var label: RichTextLabel = find_child("LyricsLabel")

@export_multiline var text: String = "Sample Text"
@export var centered: bool = true
var past_text: String = text

@export_category("Label Properties")
@export var initial_position: Vector2 = Vector2.ZERO
@export var move_distance: Vector2 = Vector2.ZERO
@export var lifetime: float = 2.5
@export var fade_in_duration: float = 0.3
@export var fade_out_duration: float = 1.0
@export_group("Font")
@export var font: FontFile
@export var font_size: int = 100


func _process(delta: float) -> void :
	if past_text != text:
		past_text = text
		create_lyrics()

func create_lyrics() -> void :
	var new_label: RichTextLabel = label.duplicate()
	new_label.text = text
	new_label.modulate.a = 0
	new_label.visible = true
	new_label.position += initial_position
	if centered: new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font", font_size)
	add_child(new_label)



	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(new_label, "modulate:a", 1, fade_in_duration)

	if move_distance != Vector2.ZERO:
		tween.tween_property(new_label, "position", initial_position + move_distance, lifetime)

	await tween.tween_property(new_label, "modulate:a", 0, fade_out_duration).set_delay(lifetime - fade_out_duration).finished


	new_label.queue_free()
