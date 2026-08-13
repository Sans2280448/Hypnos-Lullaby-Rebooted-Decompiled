@tool
class_name RubiconCharacter extends Node

@export var animation_player: AnimationPlayer:
	set(value):
		if value == animation_player:
			return

		if value != animation_player and animation_player != null:
			if animation_player.animation_finished.is_connected(note_changed):
				level_note_controller.note_changed.disconnect(note_changed)

			if animation_player.animation_changed.is_connected(update_animation_player):
				animation_player.animation_changed.disconnect(update_animation_player)

		animation_player = value

		if animation_player != null:
			animation_player.animation_changed.connect(update_animation_player)

		notify_property_list_changed()
		update_configuration_warnings()

@export var level_note_controller: RubiconLevelNoteController:
	set(value):
		if value == level_note_controller:
			return

		if is_tree_root and level_note_controller == null:
			printerr("Not recommended to assign a Note Controller on a character's scene (unless you know what you're doing!)")

		if level_note_controller != null:
			if level_note_controller.note_changed.is_connected(note_changed):
				level_note_controller.note_changed.disconnect(note_changed)

			if level_note_controller.handler_just_pressed.is_connected(_handler_pressed):
				level_note_controller.handler_just_pressed.disconnect(_handler_pressed)

			if level_note_controller.handler_just_released.is_connected(_handler_released):
				level_note_controller.handler_just_released.disconnect(_handler_released)

			var clock: RubiconLevelClock = level_note_controller.get_level_clock()
			if clock.step_change.is_connected(step_change):
				clock.step_change.disconnect(step_change)
			if clock.time_change_set.is_connected(_clock_time_change_set):
				clock.time_change_set.disconnect(_clock_time_change_set)
			if clock.animation_player.animation_started.is_connected(song_started):
				clock.animation_player.animation_started.disconnect(song_started)

			note_controller_connected.emit(false)

		level_note_controller = value
		notify_property_list_changed()
		update_configuration_warnings()

		if level_note_controller != null:
			level_note_controller.note_changed.connect(note_changed)

			_handlers_pressed.clear()
			level_note_controller.handler_just_pressed.connect(_handler_pressed)
			level_note_controller.handler_just_released.connect(_handler_released)

			var clock: RubiconLevelClock = level_note_controller.get_level_clock()
			clock.step_change.connect(step_change)
			clock.time_change_set.connect(_clock_time_change_set)
			clock.animation_player.animation_started.connect(song_started)

			note_controller_connected.emit(true)

@export_group("Singing", "singing_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var singing_should_sing: bool = true
@export var singing_sing_to_dance_interval: int = 4
@export var singing_hold_type: CharacterHoldType = CharacterHoldType.REPEAT:
	set(value):
		if value == singing_hold_type:
			return

		singing_hold_type = value
		notify_property_list_changed()
@export_storage var singing_repeat_loop_point: float = 0.125
@export_storage var singing_step_time_value: float = 1

@export_group("Dancing", "dancing_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var dancing_should_dance: bool = true
@export var dancing_measure_step: float = 0.5:
	set(value):
		if is_equal_approx(dancing_measure_step, value):
			return

		_dance_measure_step = value
		_clock_time_change_set()
	get:
		return _dance_measure_step

@export var dancing_force_dance: bool = true
@export_storage var dancing_animations: Array[StringName] = []:
	set(value):
		if value == dancing_animations:
			return

		dancing_animations = value
		_dance_anim_size = dancing_animations.size()
		_dance_anim_index = 0

@export_group("Transitions", "transition_")

@export var transition_retain_animation_queue: bool = false


@export var transition_update_queued_animations: bool = false

var state: CharacterState = CharacterState.STATE_DANCING

var _last_result: RubiconLevelNoteHitResult

var _last_sing_anim: StringName
var _last_sing_step: float

var _dance_measure_step: float = 0.5
var _dance_step_offset: int = 0
var _dance_step_interval: int = 8
var _last_dance_step: int

var _dance_anim_index: int
var _dance_anim_size: int

var _handlers_pressed: Dictionary[StringName, bool]

enum CharacterHoldType{

	NONE, 

	FREEZE, 

	REPEAT, 

	STEP_REPEAT, 
}

enum CharacterState{
	STATE_RESTING, 
	STATE_DANCING, 
	STATE_SINGING, 
	STATE_HOLDING, 
	STATE_OVERRIDE, 
}


signal note_controller_connected(value: bool)

func _valid_controller() -> bool:
	return level_note_controller != null and level_note_controller.get_level_clock() != null

func _valid_references() -> bool:
	return _valid_controller() and animation_player != null

func note_changed(result: RubiconLevelNoteHitResult, has_ending_row: bool = false) -> void :
	if not singing_should_sing:
		return

	if state == CharacterState.STATE_OVERRIDE or !_valid_controller():
		return

	if result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_NONE:
		state = CharacterState.STATE_RESTING
		return

	_last_result = result
	_last_sing_anim = get_anim_alias_from_result(_last_result)
	_last_sing_step = floori(level_note_controller.get_level_clock().time_step)

	if result.scoring_rating == RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS:
		play(_last_sing_anim, true)
		state = CharacterState.STATE_SINGING
		return

	match result.scoring_hit:
		RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
			play(_last_sing_anim, true)
			state = CharacterState.STATE_HOLDING

			if singing_hold_type == CharacterHoldType.FREEZE:
				play(_last_sing_anim, true)
				animation_player.pause()

		RubiconLevelNoteHitResult.Hit.HIT_COMPLETE:
			state = CharacterState.STATE_SINGING
			if has_ending_row and singing_hold_type != CharacterHoldType.FREEZE:
				return

			play(_last_sing_anim, true)

func _process(delta: float) -> void :
	if !_valid_references():
		return

	if singing_should_sing:
		if state == CharacterState.STATE_SINGING:
			var cur_step: int = floori(level_note_controller.get_level_clock().time_step)
			if abs(cur_step - _last_sing_step) >= singing_sing_to_dance_interval:
				state = CharacterState.STATE_RESTING

		if state == CharacterState.STATE_HOLDING and singing_hold_type == CharacterHoldType.REPEAT:
			if animation_player.is_playing() and animation_player.current_animation_position > singing_repeat_loop_point:
				play(_last_sing_anim, true)

	if dancing_should_dance and state == CharacterState.STATE_DANCING:
		if animation_player.is_playing() and dancing_animations.has(animation_player.current_animation) and !dancing_force_dance:
			return

		_last_dance_step = floori(level_note_controller.get_level_clock().time_step)
		state = CharacterState.STATE_RESTING
		_dance()

func step_change() -> void :
	if !_valid_references():
		return

	if singing_should_sing and state == CharacterState.STATE_HOLDING and singing_hold_type == CharacterHoldType.STEP_REPEAT:
		var cur_step: int = floori(level_note_controller.get_level_clock().time_step)
		var steps_since_initial: int = cur_step - _last_sing_step
		var modulo: float = fmod(steps_since_initial, singing_step_time_value)
		if steps_since_initial >= singing_step_time_value and modulo == 0:
			play(_last_sing_anim, true)

	if _should_dance():
		var cur_step: int = floori(level_note_controller.get_level_clock().time_step)
		if state == CharacterState.STATE_RESTING:
			if (cur_step - _dance_step_offset) % _dance_step_interval == 0:
				state = CharacterState.STATE_DANCING

func song_started(anim_name: StringName) -> void :
	_dance_anim_index = 0
	if state != CharacterState.STATE_OVERRIDE:
		state = CharacterState.STATE_DANCING

func _handler_pressed(id: StringName) -> void :
	_handlers_pressed[id] = true

func _handler_released(id: StringName) -> void :
	_handlers_pressed[id] = false

func _dance() -> void :
	if dancing_animations.is_empty():
		return

	var anim: StringName = dancing_animations[_dance_anim_index]
	if !anim.is_empty() and anim != &"None":
		play(anim, true)

	_dance_anim_index = wrapi(_dance_anim_index + 1, 0, _dance_anim_size)

func play(anim_name: StringName, warn_missing_animation: bool = false) -> void :
	if animation_player == null:
		printerr("Animation Player is null in character " + scene_file_path.get_file())
		return

	if !animation_player.has_animation(anim_name):
		if warn_missing_animation:
			printerr("No animation \"" + anim_name + "\" found in character: " + scene_file_path.get_file())
		return

	var same_animation_queue: Array[StringName]
	if transition_retain_animation_queue and animation_player.current_animation == anim_name:
		same_animation_queue = animation_player.get_queue()

	animation_player.stop()
	animation_player.play(anim_name)
	animation_player.seek(0.0, true)

	if transition_retain_animation_queue and not same_animation_queue.is_empty():
		for queued_animation in same_animation_queue:
			animation_player.queue(queued_animation)

func get_anim_alias_from_result(result: RubiconLevelNoteHitResult) -> StringName:
	var current_id: StringName = result.handler.get_unique_id()
	var mode_aliases: Dictionary[StringName, StringName] = get(result.handler.get_mode_id().to_lower() + "_anim_aliases")
	if mode_aliases == null or mode_aliases.is_empty():
		printerr("Couldn't get animation alias list for mode: " + result.handler.get_mode_id().to_lower())
		return &""
	if !mode_aliases.has(current_id):
		printerr("Couldn't find alias for animation: %s" % [current_id])
		return &""

	var current_anim: StringName = animations[mode_aliases[current_id]]

	if result.scoring_rating == RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS:
		current_anim = animations[mode_aliases[current_id + &"_miss"]]
	return current_anim

func update_animation_player(_old: StringName, _new: StringName) -> void :
	if not transition_update_queued_animations:
		return

	if animation_player:
		animation_player.seek(0.0, true)

func _should_dance() -> bool:
	if dancing_should_dance:
		if !level_note_controller.should_autoplay() and _handlers_pressed.values().has(true):
			for handler: int in _handlers_pressed.values().size():
				if _handlers_pressed.values()[handler]:
					var note_handler: RubiconLevelNoteHandler = level_note_controller.note_handlers.values()[handler]



					if note_handler.get_mode_id() == &"mania" and note_handler.lane_state == 2:
						return false

		return true

	return false

func _clock_time_change_set() -> void :
	if not _valid_controller():
		return

	var clock: RubiconLevelClock = level_note_controller.get_level_clock()
	var time_change: RubiconTimeChange = clock._last_time_change
	if not time_change:
		return

	_dance_step_offset = RubiconTimeChange.get_step_at_measure(clock.get_time_changes(), time_change.measure)

	_recalculate_dance_step()

func _recalculate_dance_step() -> void :
	if not _valid_controller():
		return

	var clock: RubiconLevelClock = level_note_controller.get_level_clock()
	var time_change: RubiconTimeChange = clock._last_time_change
	_dance_step_interval = floori(time_change.time_signature_numerator * time_change.time_signature_denominator * dancing_measure_step)


var is_tree_root: bool:
	get():
		if !is_inside_tree():
			return false

		if get_tree() != null and self == get_tree().edited_scene_root:
			return true
		return false

@export_storage var animations: Dictionary[StringName, StringName] = {}
var anim_player_list: PackedStringArray:
	get():
		if animation_player != null:
			var anims: PackedStringArray = [&"None"]
			anims.append_array(animation_player.get_animation_list())
			return anims
		return [&"None"]

@export_storage var modes: Array[StringName] = [&"mania"]
var _new_mode_name: StringName = &"":
	set(value):
		_new_mode_name = value.to_lower()
var _add_mode: Callable = add_mode
var _remove_mode: Callable = remove_mode
var _add_animation_group: Callable = add_animation_group


@export_storage var mania_anim_aliases: Dictionary[StringName, StringName] = {"mania_lane0": "sing_left", "mania_lane1": "sing_down", "mania_lane2": "sing_up", "mania_lane3": "sing_right", "mania_lane0_miss": "miss_left", "mania_lane1_miss": "miss_down", "mania_lane2_miss": "miss_up", "mania_lane3_miss": "miss_right"}
@export_storage var mania_anim_groups: Dictionary[StringName, int] = {"sing": 4, "miss": 4}

var mania_directions: Array[StringName] = [&"left", &"down", &"up", &"right"]

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if animation_player == null:
		warnings.append(tr(&"No root animation player assigned. Make sure to assign one under the character\'s properties"))

	if !is_tree_root and level_note_controller == null:
		warnings.append(tr(&"Characters require a note controller to work. Make sure to assign one under the character\'s properties"))

	if dancing_should_dance and dancing_animations.is_empty():
		warnings.append(tr(&"There is no current dance animation. Define it in Dancing > Animations"))




	return warnings

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary]

	match singing_hold_type:
		CharacterHoldType.REPEAT:
			properties.append({
				name = &"Singing", 
				type = TYPE_NIL, 
				usage = PROPERTY_USAGE_GROUP, 
				hint_string = "singing_", 
			})

			properties.append({
				name = &"singing_repeat_loop_point", 
				type = TYPE_FLOAT, 
				usage = PROPERTY_USAGE_EDITOR
			})
		CharacterHoldType.STEP_REPEAT:
			properties.append({
				name = &"Singing", 
				type = TYPE_NIL, 
				usage = PROPERTY_USAGE_GROUP, 
				hint_string = "singing_", 
			})

			properties.append({
				name = &"singing_step_time_value", 
				type = TYPE_FLOAT, 
				usage = PROPERTY_USAGE_EDITOR
			})

	if animation_player != null:
		properties.append({
			name = &"Dancing", 
			type = TYPE_NIL, 
			usage = PROPERTY_USAGE_GROUP, 
			hint_string = "dancing_", 
		})

		properties.append({
			name = &"dancing_animations", 
			type = TYPE_ARRAY, 
			usage = PROPERTY_USAGE_DEFAULT, 
			hint = PROPERTY_HINT_TYPE_STRING, 
			hint_string = "%d/%d:%s" % [TYPE_STRING_NAME, PROPERTY_HINT_ENUM, ",".join(anim_player_list)], 
		})






















		if !modes.is_empty():
			for mode: StringName in modes:
				properties.append({
					name = mode.capitalize(), 
					type = TYPE_NIL, 
					usage = PROPERTY_USAGE_CATEGORY
				})


























				var mode_groups: Dictionary[StringName, int] = {&"sing": 4, &"miss": 4}
				for i: int in mode_groups.size():
					var group_name: StringName = mode_groups.keys()[i]
					var group_prefix: StringName = "%s_" % [group_name.to_lower()]
					properties.append({
						name = group_name.capitalize(), 
						type = TYPE_NIL, 
						usage = PROPERTY_USAGE_GROUP, 
						hint_string = group_prefix
					})
















					for group_size: int in mode_groups[group_name]:
						var anim_id: StringName = &"%s_lane%s" % [mode, str(group_size)]
						if group_name.contains("miss"):
							anim_id += &"_miss"

						properties.append({
							name = mania_anim_aliases[anim_id] if mania_anim_aliases.has(anim_id) else anim_id, 
							hint = PROPERTY_HINT_ENUM, 
							type = TYPE_STRING_NAME, 
							usage = PROPERTY_USAGE_EDITOR, 
							hint_string = ",".join(anim_player_list)
						})

	return properties

func add_mode() -> void :
	if modes.find(_new_mode_name) != -1 or _new_mode_name.is_empty():
		return

	modes.append(_new_mode_name)
	_new_mode_name = &""
	notify_property_list_changed()

func remove_mode(mode_name: StringName) -> void :
	var mode_idx: int = modes.find(mode_name)
	modes.pop_at(mode_idx)
	notify_property_list_changed()

func add_animation_group() -> void :
	pass

func _get(property: StringName) -> Variant:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		if !animations.has(property):
			return "None"
		if animations.has(property):
			if !anim_player_list.has(animations[property]):
				return property_get_revert(property)
			return animations[property]
		return property_get_revert(property)

	if property.begins_with("_remove_mode_"):
		var split_name: PackedStringArray = property.split("_", false, 2)
		var callable = Callable(self, "remove_mode").bind(split_name[2])
		return callable

	if property == &"dancing_animations":
		return dancing_animations

	return null

func _set(property: StringName, value: Variant) -> bool:
	if (property.begins_with("sing_") or property.begins_with("miss_")):
		if value == null:
			animations[property] = &"None"

		if get(property) == value:
			return true

		if value.to_lower() == &"none":
			animations[property] = ""
			return true

		animations[property] = value
		return true





	return false

func _property_can_revert(property: StringName) -> bool:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		if get(property).to_lower() == &"none":
			return false
		return true














	return false

func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		var dir_idx: int = mania_directions.find(property.get_slice("_", 1))
		var direction: StringName = mania_directions[dir_idx]
		var anim: StringName = &"None"
		for _anim: StringName in anim_player_list:
			var anim_lower: StringName = _anim.to_lower()
			if anim_lower.contains(direction) and anim_lower.contains(property.get_slice("_", 0)):
				anim = _anim
				break
		return anim






	match property:
		&"_camera_point":
			if !is_tree_root:
				return null
			return find_child("*oint")





	return null
