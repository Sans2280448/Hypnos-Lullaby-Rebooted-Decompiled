extends HBoxContainer

@export var console: Console
@export var primary_portrait_animation: AnimationPlayer
@export var secondary_portrait_animation: AnimationPlayer
@export var switch_animation: AnimationPlayer
@export var name_label: Label
@export var next_name_label: Label
@export var prev_name_label: Label
@export var role_label: Control
@export var description_label: RichTextLabel
@export var spotlight_animation: AnimationPlayer

@export var left_arrow_anim: AnimationPlayer
@export var right_arrow_anim: AnimationPlayer
@export var left_arrow_mesh: MeshInstance3D
@export var right_arrow_mesh: MeshInstance3D
@export var material_idle: StandardMaterial3D
@export var material_select: StandardMaterial3D

@export var credits_entries: Array[LullabyCreditsEntry]
var current_portrait_index: int = 0

var enter_cooldown: float = 0.0

signal changed_credits_entry

func _ready() -> void :
	primary_portrait_animation.play(credits_entries[0].name)
	secondary_portrait_animation.play(credits_entries[1].name)
	var list_end: LullabyCreditsEntry = LullabyCreditsEntry.new()
	list_end.empty()
	credits_entries.append(list_end)
	update_labels()
	changed_credits_entry.emit()


func _process(delta: float) -> void :
	enter_cooldown -= delta


func _input(event: InputEvent) -> void :
	if not get_parent().visible:
		return

	if event.is_action_pressed("ui_accept") and enter_cooldown <= 0.0:
		console.play_sound.emit("sfx_soulroom_select_alt")
		OS.shell_open(credits_entries[current_portrait_index].socials_link)
		enter_cooldown = 1.0

	if event.is_action_pressed("ui_left"):
		current_portrait_index = wrap(current_portrait_index + 1, 0, credits_entries.size() - 1)
		update_labels()

		if left_arrow_anim.is_playing():
			left_arrow_anim.stop()
		left_arrow_anim.play("ArrowPress_24f")
		left_arrow_mesh.mesh.surface_set_material(0, material_select)

		if switch_animation.is_playing():
			switch_animation.stop()
			next_index()

		changed_credits_entry.emit()
		switch_animation.play("next")
		console.play_sound.emit("sfx_soulroom_click")

	elif event.is_action_pressed("ui_right"):
		current_portrait_index = wrap(current_portrait_index - 1, 0, credits_entries.size() - 1)
		update_labels()

		if right_arrow_anim.is_playing():
			right_arrow_anim.stop()
		right_arrow_anim.play("ArrowPress_24f")
		right_arrow_mesh.mesh.surface_set_material(0, material_select)

		if switch_animation.is_playing():
			switch_animation.stop()
		switch_animation.play("previous")

		changed_credits_entry.emit()
		console.play_sound.emit("sfx_soulroom_click")
		previous_index()
	if event.is_action_released("ui_right"):
		right_arrow_mesh.mesh.surface_set_material(0, material_idle)
	if event.is_action_released("ui_left"):
		left_arrow_mesh.mesh.surface_set_material(0, material_idle)


	if event.is_action("ui_up"):
		description_label.get_v_scroll_bar().value -= 30
	elif event.is_action("ui_down"):
		description_label.get_v_scroll_bar().value += 30

func _get_next_credit_entry() -> LullabyCreditsEntry:
	return credits_entries[wrap(current_portrait_index + 1, 0, credits_entries.size() - 1)]

func next_index():
	primary_portrait_animation.play(_get_next_credit_entry().name)
	secondary_portrait_animation.play(credits_entries[current_portrait_index].name)


func previous_index():
	primary_portrait_animation.play(credits_entries[current_portrait_index].name)
	secondary_portrait_animation.play(_get_next_credit_entry().name)


func _on_animation_player_animation_finished(_anim_name: StringName) -> void :
	primary_portrait_animation.play(credits_entries[current_portrait_index].name)
	secondary_portrait_animation.play(_get_next_credit_entry().name)


func turn_spotlight_on():
	if spotlight_animation.is_playing():
		spotlight_animation.seek(0)
	else:
		spotlight_animation.play("turn on")


func update_labels() -> void :
	name_label.text = credits_entries[current_portrait_index].name
	next_name_label.text = credits_entries[wrapi(current_portrait_index + 1, 0, credits_entries.size() - 1)].name
	prev_name_label.text = credits_entries[wrapi(current_portrait_index - 1, 0, credits_entries.size() - 1)].name
	description_label.text = credits_entries[current_portrait_index].description
	description_label.get_v_scroll_bar().value = 0
	role_label.text = credits_entries[current_portrait_index].role
