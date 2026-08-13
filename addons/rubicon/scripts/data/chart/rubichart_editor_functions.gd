class_name RubiChartEditorFunctions


static func factor_offset_and_quant(values: Array) -> void :
	for cur_quant in RubiChart.quants:
		if cur_quant > values[1]:
			break

		var is_offset_divisible: bool = values[0] %cur_quant == 0
		var is_quant_divisible: bool = values[1] %cur_quant == 0

		if not is_offset_divisible or not is_quant_divisible:
			continue

		values[0] /= cur_quant
		values[1] /= cur_quant
		break

static func chart_add_note_start(chart: RubiChart, note: RubiChartNote, measure: int, offset: int, quant: RubiChart.Quant) -> void :
	var section: RubiChartSection = chart_add_section(chart, measure)
	var row: RubiChartRow = section_add_row(section, offset, quant)
	row_add_start_note(row, note)

	note.starting_row = row

static func chart_add_note_end(chart: RubiChart, note: RubiChartNote, measure: int, offset: int, quant: RubiChart.Quant) -> void :
	var section: RubiChartSection = chart_add_section(chart, measure)
	var row: RubiChartRow = section_add_row(section, offset, quant)
	row_add_end_note(row, note)

	note.ending_row = row

static func chart_remove_note_start(chart: RubiChart, note: RubiChartNote) -> void :
	var starting_row: RubiChartRow = note.starting_row
	var ending_row: RubiChartRow = note.ending_row

	row_remove_note(starting_row, note)

	if ending_row == null:
		chart_remove_note_end(chart, note)
	else:
		cleanup_chart(chart)

static func chart_remove_note_end(chart: RubiChart, note: RubiChartNote) -> void :
	var ending_row: RubiChartRow = note.ending_row

	row_remove_note(ending_row, note)
	cleanup_chart(chart)

static func chart_move_note_start(chart: RubiChart, note: RubiChartNote, measure: int, offset: int, quant: RubiChart.Quant) -> void :
	var ending_row: RubiChartRow = note.ending_row
	chart_remove_note_start(chart, note)
	chart_add_note_start(chart, note, measure, offset, quant)

	if ending_row != null:
		chart_add_note_end(chart, note, ending_row.section.measure, ending_row.offset, ending_row.quant)

static func chart_move_note_end(chart: RubiChart, note: RubiChartNote, measure: int, offset: int, quant: RubiChart.Quant) -> void :
	chart_remove_note_end(chart, note)
	chart_add_note_end(chart, note, measure, offset, quant)

static func chart_move_note(chart: RubiChart, note: RubiChartNote, measure: int, offset: int, quant: RubiChart.Quant) -> void :
	var distance: int = 0
	var distance_quant: RubiChart.Quant = RubiChart.Quant.RUBICHART_QUANT_4
	var is_hold: bool = note.ending_row != null
	if is_hold:
		var measure_distance: int = note.ending_row.section.measure - note.starting_row.section.measure

		var ending_quant_higher: bool = note.ending_row.quant > note.starting_row.quant
		var starting_quant_higher: bool = note.starting_row.quant > note.ending_row.quant
		distance_quant = maxi(note.starting_row.quant, note.ending_row.quant)

		var starting_offset: int = note.starting_row.offset
		if ending_quant_higher:
			starting_offset *= note.ending_row.quant / note.starting_row.quant

		var ending_offset: int = note.ending_row.offset
		if starting_quant_higher:
			ending_offset *= note.starting_row.quant / note.ending_row.quant

		distance = (measure_distance * distance_quant) + ending_offset - starting_offset

	chart_remove_note_start(chart, note)
	chart_add_note_start(chart, note, measure, offset, quant)
	if not is_hold:
		return

	var distance_quant_higher: bool = distance_quant > quant
	var param_quant_higher: bool = quant > distance_quant
	var ending_quant: RubiChart.Quant = maxi(quant, distance_quant)

	if distance_quant_higher:
		offset *= distance_quant / quant

	if param_quant_higher:
		distance_quant *= quant / distance_quant

	var total_distance: int = offset + distance_quant
	var ending_measure: int = total_distance / ending_quant
	var end_offset: int = total_distance % ending_quant

	chart_add_note_end(chart, note, ending_measure, end_offset, ending_quant)

static func chart_add_section(chart: RubiChart, measure: int) -> RubiChartSection:
	var section: RubiChartSection = get_section_at_measure(chart.sections, measure)
	if section != null:
		return section

	section = RubiChartSection.new()
	section.measure = measure

	chart.sections.append(section)
	sort_sections_by_measure(chart.sections)
	return section

static func chart_remove_section(chart: RubiChart, section: RubiChartSection) -> void :
	chart.sections.remove_at(chart.sections.find(section))
	sort_sections_by_measure(chart.sections)

static func chart_remove_section_at(chart: RubiChart, measure: int) -> void :
	var section: RubiChartSection = get_section_at_measure(chart.sections, measure)
	if section == null:
		return

	chart_remove_section(chart, section)

static func get_section_at_measure(sections: Array[RubiChartSection], measure: int) -> RubiChartSection:
	var matching_section: Array[RubiChartSection] = sections.filter(section_is_at_measure.bind(measure))
	return null if matching_section.is_empty() else matching_section.front()

static func section_is_at_measure(section: RubiChartSection, measure: int) -> bool:
	return section.measure == measure

static func cleanup_chart(chart: RubiChart) -> void :
	for section in chart.sections:
		section_cleanup_rows(section)
		if not section.rows.is_empty():
			continue

		chart.sections.remove_at(chart.sections.find(section))

	sort_sections_by_measure(chart.sections)

static func sort_sections_by_measure(sections: Array[RubiChartSection]) -> void :
	sections.sort_custom(compare_sections_by_measure)

static func compare_sections_by_measure(x: RubiChartSection, y: RubiChartSection) -> bool:
	return x.measure < y.measure

static func section_add_row(section: RubiChartSection, offset: int, quant: RubiChart.Quant) -> RubiChartRow:
	var row: RubiChartRow = section_get_row(section, offset, quant)
	if row != null:
		return row

	var values: Array = [offset, quant]
	factor_offset_and_quant(values)

	row = RubiChartRow.new()
	row.offset = values[0]
	row.quant = values[1]

	section.rows.append(row)
	sort_rows(section.rows)

	return row

static func section_remove_row(section: RubiChartSection, row: RubiChartRow) -> void :
	section.rows.remove_at(section.rows.find(row))
	sort_rows(section.rows)

static func section_remove_row_at(section: RubiChartSection, offset: int, quant: RubiChart.Quant) -> void :
	var row: RubiChartRow = section_get_row(section, offset, quant)
	if row == null:
		return

	section_remove_row(section, row)

static func section_cleanup_rows(section: RubiChartSection) -> void :
	for row in section.rows:
		if not row.starts.is_empty() or not row.ends.is_empty():
			continue

		section.rows.remove_at(section.rows.find(row))

	sort_rows(section.rows)

static func section_get_row(section: RubiChartSection, offset: int, quant: RubiChart.Quant) -> RubiChartRow:
	var values: Array = [offset, quant]
	factor_offset_and_quant(values)

	var matching_rows: Array[RubiChartRow] = section.rows.filter(row_matches_value.bind(values[0], values[1]))
	return null if matching_rows.is_empty() else matching_rows.front()

static func section_has_row(section: RubiChartSection, offset: int, quant: RubiChart.Quant) -> bool:
	var values: Array = [offset, quant]
	factor_offset_and_quant(values)
	return section.rows.any(row_matches_value.bind(values[0], values[1]))

static func row_matches_value(row: RubiChartRow, offset: int, quant: RubiChart.Quant) -> bool:
	return row.offset == offset and row.quant == quant

static func sort_rows(rows: Array[RubiChartRow]) -> void :
	rows.sort_custom(compare_rows)

static func compare_rows(x: RubiChartRow, y: RubiChartRow) -> bool:
	return (float(x.offset) / float(x.quant)) < (float(y.offset) / float(y.quant))

static func row_add_start_note(row: RubiChartRow, note: RubiChartNote) -> void :
	if row.has_note_with_id(note.id):
		return

	row.starts.append(note)

static func row_add_end_note(row: RubiChartRow, note: RubiChartNote) -> void :
	if row.has_note_with_id(note.id):
		return

	row.ends.append(note)

static func row_remove_note(row: RubiChartRow, note: RubiChartNote) -> void :
	if row.starts.has(note):
		row.starts.remove_at(row.starts.find(note))

	if row.ends.has(note):
		row.ends.remove_at(row.ends.has(note))

static func row_remove_note_with_id(row: RubiChartRow, id: String) -> void :
	var note: RubiChartNote = row.get_note_with_id(id, true)

	if note != null:
		row_remove_note(row, note)
