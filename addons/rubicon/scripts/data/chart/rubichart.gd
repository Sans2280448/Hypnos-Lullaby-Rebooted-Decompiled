@tool
class_name RubiChart extends Resource

const VERSION_MAJOR: int = 2
const VERSION_MINOR: int = 0
const VERSION_PATCH: int = 0
const VERSION_BUILD: int = 0

enum Quant
{
	RUBICHART_QUANT_4 = 4, 
	RUBICHART_QUANT_8 = 8, 
	RUBICHART_QUANT_12 = 12, 
	RUBICHART_QUANT_16 = 16, 
	RUBICHART_QUANT_24 = 24, 
	RUBICHART_QUANT_32 = 32, 
	RUBICHART_QUANT_48 = 48, 
	RUBICHART_QUANT_64 = 64, 
	RUBICHART_QUANT_128 = 128
}

static var quants: Array[Quant] = [
	RubiChart.Quant.RUBICHART_QUANT_4, 
	RubiChart.Quant.RUBICHART_QUANT_8, 
	RubiChart.Quant.RUBICHART_QUANT_12, 
	RubiChart.Quant.RUBICHART_QUANT_16, 
	RubiChart.Quant.RUBICHART_QUANT_24, 
	RubiChart.Quant.RUBICHART_QUANT_32, 
	RubiChart.Quant.RUBICHART_QUANT_48, 
	RubiChart.Quant.RUBICHART_QUANT_64, 
	RubiChart.Quant.RUBICHART_QUANT_128
]

@export var scroll_multiplier: float = 1.0
@export var sections: Array[RubiChartSection]
@export var scroll_velocities: Array[RubiChartScrollVelocity] = [RubiChartScrollVelocity.new()]

func initialize(time_changes: Array[RubiconTimeChange]) -> void :
	RubiconTimeChange.update(time_changes)

	for section in sections:
		section.chart = self

		for row in section.rows:
			row.section = section
			row.initaliize(time_changes)

			for start in row.starts:
				start.starting_row = row

			for end in row.ends:
				end.ending_row = row

	scroll_velocities[0].initialize(time_changes)
	for s in range(1, scroll_velocities.size()):
		var current: RubiChartScrollVelocity = scroll_velocities[s]
		var previous: RubiChartScrollVelocity = scroll_velocities[s - 1]

		current.initialize_with_previous(time_changes, previous)

func get_notes_of_id(id: String, include_ends: bool = false) -> Array[RubiChartNote]:
	var notes: Array[RubiChartNote]
	for section in sections:
		for row in section.rows:
			var note: RubiChartNote = row.get_note_with_id(id, include_ends)
			if note != null:
				notes.append(note)

	return notes
