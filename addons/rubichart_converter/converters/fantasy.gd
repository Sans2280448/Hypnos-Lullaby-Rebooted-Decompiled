static func get_new_parameters() -> Dictionary[String, Variant]:
	return Dictionary()

static func needs_metadata() -> bool:
	return false

static func convert_chart(args: Array[String]) -> void :
	var file_path: String = args[0]
	var text: String = FileAccess.get_file_as_string(file_path)
	var data: Dictionary = JSON.parse_string(text)

	var time_sig_numerator: float = data["timeSigNumerator"]
	var time_sig_denominator: float = data["timeSigDenominator"]

	var metadata: RubiconLevelMetadata = RubiconLevelMetadata.new()
	for change: Dictionary in data["bpms"]:
		var time_change: RubiconTimeChange = RubiconTimeChange.new()
		time_change.measure = change["time"]
		time_change.bpm = change["bpm"]
		time_change.time_signature_numerator = time_sig_numerator
		time_change.time_signature_denominator = time_sig_denominator
		metadata.time_changes.append(time_change)

	var charts: Array[RubiChart] = []
	for fantasy_chart: Dictionary in data["characterCharts"]:
		var chart: RubiChart = RubiChart.new()
		chart.scroll_multiplier = data["scrollSpeed"]

		for fantasy_note: Dictionary in fantasy_chart["notes"]:
			var note: RubiChartNote = RubiChartNote.new()
			note.id = "mania_lane%s" % int(fantasy_note["lane"])

			var note_type: String = fantasy_note["type"]
			if note_type != "normal":
				note.type = fantasy_note["type"]

			chart_add_note_at_measure_time(chart, note, fantasy_note["time"], fantasy_note["length"])

		charts.append(chart)

	var directory: String = file_path.get_base_dir()
	var file_name: String = file_path.get_file().replace("." + file_path.get_extension(), "")

	for i in charts.size():
		ResourceSaver.save(charts[i], "%s/%s_%s.tres" % [directory, file_name, i])

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
