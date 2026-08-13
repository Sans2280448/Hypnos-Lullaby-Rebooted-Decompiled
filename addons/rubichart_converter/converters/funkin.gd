static func get_new_parameters() -> Dictionary[String, Variant]:
	return Dictionary()

static func needs_metadata() -> bool:
	return false

static func convert_chart(args: Array[String]) -> void :
	var file_path: String = args[0]
	var text: String = FileAccess.get_file_as_string(file_path)
	var swag_song: Dictionary = JSON.parse_string(text)["song"]

	var metadata: RubiconLevelMetadata = RubiconLevelMetadata.new()

	var first_tc: RubiconTimeChange = RubiconTimeChange.new()
	first_tc.bpm = swag_song["bpm"]
	first_tc.measure = 0
	first_tc.time_signature_numerator = 4
	first_tc.time_signature_denominator = 4

	metadata.time_changes.append(first_tc)

	var notemaps: Array[RubiChart] = [RubiChart.new(), RubiChart.new(), RubiChart.new()]
	for map in notemaps:
		map.scroll_multiplier = swag_song["speed"]

	var sections: Array = swag_song["notes"]
	for measure in sections.size():
		var section: Dictionary = sections[measure]
		if not section.has("changeBPM") or not section["changeBPM"]:
			continue

		var time_change: RubiconTimeChange = RubiconTimeChange.new()
		time_change.measure = measure
		time_change.bpm = section["bpm"]
		time_change.time_signature_denominator = section["lengthInSteps"] / 4
		time_change.time_signature_numerator = 4

		metadata.time_changes.append(time_change)

	RubiconTimeChange.update(metadata.time_changes)

	var last_camera: int = 0
	var panning_changes: Dictionary[float, String]
	for measure in sections.size():
		var section: Dictionary = sections[measure]
		var measure_bpm: float = metadata.time_changes.filter( func(x): return x.measure <= measure).front().bpm
		var is_player_section: bool = section["mustHitSection"]
		var is_speaker_section: bool = section.has("gfSection") and section["gfVersion"]
		var section_camera = 1 if is_player_section else 0

		if is_speaker_section:
			section_camera = 2

		if last_camera != section_camera:
			var camera_tag: String = ""
			match section_camera:
				0:
					camera_tag = "Opponent"
				1:
					camera_tag = "Player"
				2:
					camera_tag = "Speaker"

			panning_changes[RubiconTimeChange.get_millisecond_at_measure(metadata.time_changes, measure) / 1000.0] = camera_tag
			last_camera = section_camera

		var notes: Array = section["sectionNotes"]
		for n in notes.size():
			var data: Array = notes[n]
			var starting_ms: float = data[0]

			var measure_time: float = RubiconTimeChange.get_measure_at_millisecond(metadata.time_changes, starting_ms)
			var lane: int = data[1]
			var measure_length: float = RubiconTimeChange.get_measure_at_millisecond(metadata.time_changes, starting_ms + data[2]) - measure_time

			var note: RubiChartNote = RubiChartNote.new()
			note.id = "mania_lane%s" % (lane % 4)
			if data.size() > 3:
				note.type = data[3]

			if lane <= 3:
				if is_player_section:
					chart_add_note_at_measure_time(notemaps[1], note, measure_time, measure_length)
				else:
					if is_speaker_section:
						chart_add_note_at_measure_time(notemaps[2], note, measure_time, measure_length)
					else:
						chart_add_note_at_measure_time(notemaps[0], note, measure_time, measure_length)
			elif lane <= 7:
				if is_player_section:
					chart_add_note_at_measure_time(notemaps[0], note, measure_time, measure_length)
				else:
					chart_add_note_at_measure_time(notemaps[1], note, measure_time, measure_length)
			else:
				chart_add_note_at_measure_time(notemaps[2], note, measure_time, measure_length)

	var directory: String = file_path.get_base_dir()
	var file_name: String = file_path.get_file().replace("." + file_path.get_extension(), "")

	ResourceSaver.save(notemaps[0], "%s/%s_Opponent.tres" % [directory, file_name])
	ResourceSaver.save(notemaps[1], "%s/%s_Player.tres" % [directory, file_name])
	ResourceSaver.save(notemaps[2], "%s/%s_Speaker.tres" % [directory, file_name])

	ResourceSaver.save(metadata, "%s/Meta.tres" % [directory])

static func is_equal_approx_with_tolerance(a: float, b: float, tolerance: float) -> bool:
	if a == b:
		return true

	return absf(a - b) < tolerance

static func chart_add_note_at_measure_time(chart: RubiChart, note: RubiChartNote, measure_time: float, length: float) -> void :
	var base_measure: int = floori(measure_time)
	var measure_offset: float = measure_time - base_measure

	var offset: int = clampi(roundi(measure_offset * RubiChart.quants.back()), 0, RubiChart.quants.back() - 1)
	var quant: RubiChart.Quant = RubiChart.quants.back()
	for cur_quant in RubiChart.quants:
		var result: float = measure_offset * cur_quant
		var is_snapped: bool = fmod(result, 1) == 0
		if not is_snapped:
			var rounded_result: int = roundi(result)
			if not is_equal_approx_with_tolerance(result, rounded_result, 0.1):
				continue

			offset = rounded_result
			quant = cur_quant
			break

		offset = result
		quant = cur_quant
		break

	RubiChartEditorFunctions.chart_add_note_start(chart, note, base_measure, offset, quant)
	if length <= 0:
		return

	base_measure = floori(measure_time + length)
	measure_offset = measure_time + length - base_measure

	offset = clampi(roundi(measure_offset * RubiChart.quants.back()), 0, RubiChart.quants.back() - 1)
	quant = RubiChart.quants.back()
	for cur_quant in RubiChart.quants:
		var result: float = measure_offset * cur_quant
		var is_snapped: bool = fmod(result, 1) == 0
		if not is_snapped:
			var rounded_result: int = roundi(result)
			if not is_equal_approx_with_tolerance(result, rounded_result, 0.1):
				continue

			offset = rounded_result
			quant = cur_quant
			break

		offset = result
		quant = cur_quant
		break

	RubiChartEditorFunctions.chart_add_note_end(chart, note, base_measure, offset, quant)
