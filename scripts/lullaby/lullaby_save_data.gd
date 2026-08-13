class_name LullabySaveData
extends Node


signal new_cartridge_selected(cart: StringName)
signal tokens_changed(count: int)

const VERSION_MAJOR = 1
const VERSION_MINOR = 0
const VERSION_PATCH = 0
const VERSION_BUILD = 0

const SAVE_PATH: String = "user://save.bin"

var flags: Dictionary[StringName, bool] = {
	&"warning_seen": false, 
	&"first_boot_seen": false, 
	&"fuckno_seen": false, 
	&"splash_seen": false, 

	&"intro_seen": false, 
	&"intro_sign_seen": false, 
	&"pokedhatfinale": false, 
	&"got_token": false, 

	&"playedmonochrome": false, 
	&"playedsafety": false, 
	&"playedchimera": false, 

	&"seen_monochrome_prop": false, 
	&"seen_safety_lullaby_prop": false, 
	&"seen_chimera_prop": false, 

	&"monochrome_beaten": false, 
	&"monochrome_unlocked": false, 
	&"monochrome_failed_seen": false, 
	&"monochrome_passed_seen": false, 

	&"safety_lullaby_beaten": false, 
	&"safety_lullaby_unlocked": true, 
	&"safety_lullaby_failed_seen": false, 
	&"safety_lullaby_passed_seen": false, 

	&"chimera_beaten": false, 
	&"chimera_unlocked": false, 
	&"chimera_2nd_phase_first": false, 
	&"chimera_failed_seen": false, 
	&"chimera_passed_seen": false, 

	&"console_area_seen": false, 
	&"console_boot_seen": false, 
	&"console_on": false, 

	&"credits_scroll_seen": false, 
	&"outro_seen": false
}

var kollectadex_index: int = 0
var cartridge_selected: StringName = &"safety_lullaby":
	set(v):
		if cartridge_selected != v:
			cartridge_selected = v
			new_cartridge_selected.emit(cartridge_selected)
	get:
		if cartridge_selected.is_empty():
			return &"safety_lullaby"
		else:
			return cartridge_selected

var tokens: int = 0:
	set(v):
		if tokens != v:
			tokens = v
			tokens_changed.emit(tokens)

var just_got_token: = false

var song_grades: Dictionary[StringName, LullabySongGrade] = {}

var misc_fuckno: bool = false

var notepad_ids_seen: Array[int] = []
var notepad_ids_unlocked: Array[int] = []

func _ready() -> void :
	var err: Error = load_from(SAVE_PATH)
	if err == ERR_FILE_NOT_FOUND:
		save(SAVE_PATH)


func get_flag(flag: StringName) -> bool:
	if not has_flag(flag):
		ErrorHandler.show_error("Flag \"%s\" was not found." % flag, ERR_INVALID_DATA)
		return false

	return flags[flag]


func has_flag(flag: StringName) -> bool:
	return flags.has(flag)


func set_flag(flag: StringName, value: bool) -> void :
	flags[flag] = value


func has_passed_song(song: StringName) -> bool:
	return song_grades.has(song) and song_grades[song].clear >= LullabySongGrade.Clear.CLEAR_PASSED


func save(path: String = SAVE_PATH) -> void :
	var writer: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if FileAccess.get_open_error() != OK:
		await ErrorHandler.show_warning("Save data could not be flushed to disk.", FileAccess.get_open_error())
		return

	if misc_fuckno:
		writer.store_buffer("FUCKNO".to_utf8_buffer())

	writer.store_buffer("CABINOVL".to_utf8_buffer())
	writer.store_32(encode_version_number())

	writer.store_32(tokens)

	var songs_marked: Array[StringName] = song_grades.keys()
	writer.store_32(songs_marked.size())
	for song_name in songs_marked:
		var grade: LullabySongGrade = song_grades[song_name]
		var name_buffer: PackedByteArray = String(song_name).to_utf8_buffer()

		writer.store_32(name_buffer.size())
		writer.store_buffer(name_buffer)

		writer.store_32(grade.score)
		writer.store_32(grade.highest_combo)
		writer.store_double(grade.accuracy)
		writer.store_32(grade.misses)
		writer.store_8(grade.rank)
		writer.store_8(grade.clear)

	var flag_names: Array[StringName] = flags.keys()
	writer.store_32(flag_names.size())
	for flag in flag_names:
		var flag_buffer: PackedByteArray = String(flag).to_utf8_buffer()

		writer.store_32(flag_buffer.size())
		writer.store_buffer(flag_buffer)

		writer.store_8(flags[flag])

	writer.store_8(kollectadex_index)

	var cartridge_buffer: PackedByteArray = String(cartridge_selected).to_utf8_buffer()
	writer.store_32(cartridge_buffer.size())
	writer.store_buffer(cartridge_buffer)

	writer.store_8(notepad_ids_seen.size())
	for index in notepad_ids_seen:
		writer.store_8(index)

	writer.store_8(notepad_ids_unlocked.size())
	for index in notepad_ids_unlocked:
		writer.store_8(index)


func load_from(path: String = SAVE_PATH) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND

	var reader: FileAccess = FileAccess.open(path, FileAccess.READ)

	var fuckno_check: PackedByteArray = reader.get_buffer(6)
	var is_valid_save: bool = false

	var is_fuckno: bool = fuckno_check == "FUCKNO".to_utf8_buffer()
	if is_fuckno:
		misc_fuckno = true
		is_valid_save = _validate(reader.get_buffer(8))
	else:
		fuckno_check.append_array(reader.get_buffer(2))
		is_valid_save = _validate(fuckno_check)

	if not is_valid_save:
		if is_fuckno:
			save(path)
		else:
			ErrorHandler.show_error("Save data could not be loaded.\n\nPlease delete your save data immediately.", ERR_FILE_UNRECOGNIZED)
			return ERR_FILE_UNRECOGNIZED

	var version_raw: int = reader.get_32()
	match version_raw:
		_:
			pass

	tokens = reader.get_32()

	var songs_to_parse: int = reader.get_32()
	while songs_to_parse > 0:
		var name_length: int = reader.get_32()
		var song_name: StringName = StringName(reader.get_buffer(name_length).get_string_from_utf8())

		var grade: LullabySongGrade = LullabySongGrade.new()
		grade.score = reader.get_32()
		grade.highest_combo = reader.get_32()
		grade.accuracy = reader.get_double()
		grade.misses = reader.get_32()
		grade.clear = reader.get_8() as LullabySongGrade.Clear
		grade.rank = reader.get_8() as LullabySongGrade.Rank

		song_grades[song_name] = grade

		songs_to_parse -= 1

	var flags_to_parse: int = reader.get_32()
	while flags_to_parse > 0:
		var flag_length: int = reader.get_32()
		var flag: StringName = StringName(reader.get_buffer(flag_length).get_string_from_utf8())

		flags[flag] = bool(reader.get_8())
		flags_to_parse -= 1

	cartridge_selected = &"safety_lullaby"

	if reader.eof_reached():
		return OK

	kollectadex_index = reader.get_8()

	if reader.eof_reached():
		return OK

	var cartridge_length: int = reader.get_32()
	cartridge_selected = StringName(reader.get_buffer(cartridge_length).get_string_from_utf8())

	if reader.eof_reached():
		return OK

	var notepad_ids_seen_len: int = reader.get_8()
	for i in range(0, notepad_ids_seen_len):
		var seen_index: int = reader.get_8()
		notepad_ids_seen.push_back(seen_index)

	var notepad_ids_unlocked_len: int = reader.get_8()
	for i in range(0, notepad_ids_unlocked_len):
		var unlocked_index: int = reader.get_8()
		notepad_ids_unlocked.push_back(unlocked_index)

	return OK


func _validate(bytes: PackedByteArray) -> bool:
	return bytes == "CABINOVL".to_utf8_buffer()


func encode_version_number() -> int:
	return (VERSION_MAJOR << 24) | (VERSION_MINOR << 16) | (VERSION_PATCH << 8) | VERSION_BUILD


func decode_version_number(raw: int) -> Array[int]:
	var version: Array[int] = []
	version.resize(4)
	version[0] = (raw & 4278190080) >> 24
	version[1] = (raw & 16711680) >> 16
	version[2] = (raw & 65280) >> 8
	version[3] = raw & 255

	return version

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_EXIT_TREE:
			SaveData.save()

func reset() -> void :
	for flag in flags:
		if flag == &"fuckno_seen":
			continue
		flags[flag] = false
	set_flag(&"safety_lullaby_unlocked", true)

	kollectadex_index = 0
	cartridge_selected = &"safety_lullaby"
	tokens = 0
	just_got_token = false
	song_grades = {}
	notepad_ids_seen = []
	notepad_ids_unlocked = []

	save(SAVE_PATH)
	SceneChanger.change_to("res://rooms/scn_boot.tscn", &"hypno")
