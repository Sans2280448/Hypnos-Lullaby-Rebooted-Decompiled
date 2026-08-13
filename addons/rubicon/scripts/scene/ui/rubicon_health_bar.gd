@tool
extends ProgressBar
class_name RubiconHealthBar

@export var health_module: RubiconHealthModule:
	set(value):
		if value != health_module and health_module != null and health_module.health_changed.is_connected(health_changed):
			health_module.disconnect("health_changed", health_changed)

		health_module = value
		update_configuration_warnings()

		if health_module != null:
			health_module.connect("health_changed", health_changed)

@export var path: Path2D
@export var path_follow: PathFollow2D:
	set(_value):
		path_follow = _value
		_on_value_changed(value)
@export_tool_button("Flip Bar", "Blend") var flip_bar_button: Callable

func _ready() -> void :
	flip_bar_button = flip_bar
	_on_value_changed(value)

	if health_module != null:
		value = health_module.starting_health
		min_value = health_module.min_health
		max_value = health_module.max_health

func health_changed() -> void :
	value = health_module.health

func _on_value_changed(value: float) -> void :
	if path_follow != null and path_follow.is_inside_tree():
		path_follow.progress_ratio = get_as_ratio()

func flip_bar() -> void :

	if path != null and path.curve != null and path.curve.point_count > 1:
		var reversed_array: Array[Vector2]
		for point: int in path.curve.point_count:
			reversed_array.append(path.curve.get_point_in(point))

		reversed_array.reverse()
		for point: int in reversed_array.size():
			path.curve.set_point_in(point, reversed_array[point])
