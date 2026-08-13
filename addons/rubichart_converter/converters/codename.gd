static func get_new_parameters() -> Dictionary[String, Variant]:
	return Dictionary()

static func needs_metadata() -> bool:
	return true

static func convert_chart(args: Array[String]) -> void :
	if args.is_empty():
		return

	var chart_path: String = args[0]
	var meta_path: String = args[1]
	var directory: String = chart_path.get_base_dir()
	var file_name: String = chart_path.get_file().get_basename()

	var chart_text: String = FileAccess.get_file_as_string(chart_path)
	var chart_parse: Dictionary = JSON.parse_string(chart_text)

	var meta_text: String = FileAccess.get_file_as_string(meta_path)
	var meta_parse: Dictionary = JSON.parse_string(meta_text)

	var song_name: StringName = meta_parse["displayName"]
	var metadata: RubiconLevelMetadata = RubiconLevelMetadata.new()

	var first_tc: RubiconTimeChange = RubiconTimeChange.new()
	first_tc.bpm = meta_parse["bpm"]
	first_tc.measure = 0
	first_tc.time_signature_numerator = meta_parse["beatsPerMeasure"]
	first_tc.time_signature_denominator = meta_parse["stepsPerBeat"]

	metadata.time_changes.append(first_tc)

	var time_change_events: Dictionary[float, Dictionary]
	var unknown_events: Array[String]
	for event: Dictionary in chart_parse["events"]:
		var event_name: String = event["name"]
		match event_name:
			"BPM Change":
				var new_time_change: Dictionary
				if time_change_events.has(event["time"]):
					new_time_change = time_change_events[event["time"]]

				new_time_change.set("bpm", event["params"][0])
				time_change_events.set(event["time"], new_time_change)

			"Time Signature Change":
				var new_time_change: Dictionary
				if time_change_events.has(event["time"]):
					new_time_change = time_change_events[event["time"]]

				new_time_change.set("num", event["params"][0])
				new_time_change.set("denom", event["params"][1])
				time_change_events.set(event["time"], new_time_change)

			"Camera Movement":
				pass

			_:
				if !unknown_events.has(event_name):
					print("Unknown event '" + event_name + "' skipped")
					unknown_events.append(event_name)
				continue

	for time: float in time_change_events.keys():
		var time_change_data: Dictionary = time_change_events[time]
		var last_time_change: RubiconTimeChange = metadata.time_changes[metadata.time_changes.size() - 1]

		var new_time_change: RubiconTimeChange = RubiconTimeChange.new()
		new_time_change.measure = RubiconTimeChange.get_measure_at_millisecond(metadata.time_changes, time)
		new_time_change.bpm = time_change_data["bpm"] if time_change_data.has("bpm") else last_time_change.bpm
		new_time_change.time_signature_numerator = time_change_data["num"] if time_change_data.has("num") else last_time_change.time_signature_numerator
		new_time_change.time_signature_denominator = time_change_data["denom"] if time_change_data.has("denom") else last_time_change.time_signature_denominator

		metadata.time_changes.append(new_time_change)
		RubiconTimeChange.update(metadata.time_changes)



	var note_types: PackedStringArray = chart_parse["noteTypes"]
	for strumline: Dictionary in chart_parse["strumLines"]:
		var _name: StringName = strumline["position"]
		var chart: RubiChart = RubiChart.new()

		if !strumline.has("notes") or strumline["notes"].is_empty():
			continue

		for note_data: Dictionary in strumline["notes"]:
			var lane: int = note_data["id"]
			var length_ms: float = note_data["sLen"]
			var starting_ms: float = note_data["time"]
			var type_id: int = note_data["type"]

			var measure_time: float = RubiconTimeChange.get_measure_at_millisecond(metadata.time_changes, starting_ms)
			var measure_length: float = RubiconTimeChange.get_measure_at_millisecond(metadata.time_changes, starting_ms + length_ms) - measure_time

			var note: RubiChartNote = RubiChartNote.new()
			note.id = "mania_lane%s" % [lane]
			if type_id > 0:
				note.type = note_types[type_id - 1]

			chart_add_note_at_measure_time(chart, note, measure_time, measure_length)

		ResourceSaver.save(chart, "%s/%s_%s.tres" % [directory, file_name, _name])

	ResourceSaver.save(metadata, "%s/meta.tres" % [directory])

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
