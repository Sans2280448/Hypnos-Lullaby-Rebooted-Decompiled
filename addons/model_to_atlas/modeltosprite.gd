@tool
extends SubViewport


@export_category("Animation")


@export var animation_player: AnimationPlayer


@export var animation_name: StringName = &"RESET"



@export var use_animation_length: bool = true


@export_range(0.01, 300.0, 0.01, "suffix:s")
var capture_duration: float = 1.0


@export_category("Capture")


@export_range(1, 240, 1, "suffix: FPS")
var capture_framerate: int = 12


@export_range(1, 256, 1)
var atlas_columns: int = 6



@export var include_final_frame: bool = false


@export var flip_y: bool = false


@export_category("Export")


@export_dir
var output_directory: String = "res://"


@export var output_filename: String = "animation_atlas"


@export var overwrite_existing: bool = true


@export_category("Actions")

@export_tool_button("Capture Animation Atlas")
var capture_button: Callable = capture_animation_atlas


var _is_capturing: bool = false


func capture_animation_atlas() -> void :
	if _is_capturing:
		push_warning("An animation capture is already running.")
		return

	if not is_instance_valid(animation_player):
		push_error("Assign an AnimationPlayer before capturing.")
		return

	if animation_name.is_empty():
		push_error("Enter an animation name.")
		return

	if not animation_player.has_animation(animation_name):
		push_error(
			"AnimationPlayer does not contain an animation named \"%s\"."
			%animation_name
		)
		return

	if size.x <= 0 or size.y <= 0:
		push_error("The SubViewport size must be greater than zero.")
		return

	if capture_framerate <= 0:
		push_error("Capture Framerate must be greater than zero.")
		return

	if atlas_columns <= 0:
		push_error("Atlas Columns must be at least 1.")
		return

	var animation: Animation = animation_player.get_animation(animation_name)

	if animation == null:
		push_error(
			"Could not retrieve animation \"%s\"."
			%animation_name
		)
		return

	var duration: float = capture_duration

	if use_animation_length:
		duration = animation.length

	if duration <= 0.0:
		push_error("The capture duration must be greater than zero.")
		return

	var full_output_path: String = _get_output_path()

	if full_output_path.is_empty():
		return

	if FileAccess.file_exists(full_output_path) and not overwrite_existing:
		push_error(
			"File already exists and Overwrite Existing is disabled:\n%s"
			%full_output_path
		)
		return

	if not _ensure_output_directory_exists():
		return

	_is_capturing = true

	var original_update_mode: SubViewport.UpdateMode = render_target_update_mode
	var original_animation: StringName = animation_player.current_animation
	var original_position: float = animation_player.current_animation_position
	var original_playing: bool = animation_player.is_playing()
	var original_speed_scale: float = animation_player.speed_scale

	render_target_update_mode = SubViewport.UPDATE_ALWAYS


	animation_player.play(animation_name)
	animation_player.pause()

	var frame_interval: float = 1.0 / float(capture_framerate)



	var total_frames: int = int(
		ceil(duration * float(capture_framerate))
	)

	if include_final_frame:
		total_frames += 1

	total_frames = max(total_frames, 1)

	var atlas_rows: int = int(
		ceil(float(total_frames) / float(atlas_columns))
	)

	var frame_size: = Vector2i(
		int(size.x), 
		int(size.y)
	)

	var atlas_size: = Vector2i(
		frame_size.x * atlas_columns, 
		frame_size.y * atlas_rows
	)


	await RenderingServer.frame_post_draw

	var test_image: Image = get_texture().get_image()

	if test_image == null or test_image.is_empty():
		push_error("The SubViewport texture could not be captured.")

		_restore_animation_state(
			original_update_mode, 
			original_animation, 
			original_position, 
			original_playing, 
			original_speed_scale
		)
		return

	if flip_y:
		test_image.flip_y()

	var atlas: Image = Image.create_empty(
		atlas_size.x, 
		atlas_size.y, 
		false, 
		test_image.get_format()
	)

	atlas.fill(Color.TRANSPARENT)

	print(
		"Capturing animation '%s': %d frames at %d FPS."
		%[
			animation_name, 
			total_frames, 
			capture_framerate
		]
	)

	for frame_index: int in total_frames:
		var frame_time: float = float(frame_index) * frame_interval

		if include_final_frame and frame_index == total_frames - 1:
			frame_time = duration
		else:
			frame_time = min(frame_time, duration)


		animation_player.seek(frame_time, true)


		await RenderingServer.frame_post_draw

		var frame_image: Image = get_texture().get_image()

		if frame_image == null or frame_image.is_empty():
			push_warning(
				"Could not capture frame %d at %.3f seconds."
				%[frame_index, frame_time]
			)
			continue

		if flip_y:
			frame_image.flip_y()

		if frame_image.get_format() != atlas.get_format():
			frame_image.convert(atlas.get_format())

		var column: int = frame_index % atlas_columns
		var row: int = int(frame_index / atlas_columns)

		var destination: = Vector2i(
			column * frame_size.x, 
			row * frame_size.y
		)

		atlas.blit_rect(
			frame_image, 
			Rect2i(Vector2i.ZERO, frame_size), 
			destination
		)

		print(
			"Captured frame %d/%d at %.3f seconds."
			%[
				frame_index + 1, 
				total_frames, 
				frame_time
			]
		)

	var save_error: Error = atlas.save_png(full_output_path)

	if save_error == OK:
		print("Animation atlas saved to: ", full_output_path)
		print("Atlas size: ", atlas_size)
		print("Individual frame size: ", frame_size)


		if full_output_path.begins_with("res://"):
			EditorInterface.get_resource_filesystem().scan()
	else:
		push_error(
			"Failed to save atlas to '%s'. Error code: %d"
			%[full_output_path, save_error]
		)

	_restore_animation_state(
		original_update_mode, 
		original_animation, 
		original_position, 
		original_playing, 
		original_speed_scale
	)


func _get_output_path() -> String:
	var directory: String = output_directory.strip_edges()
	var filename: String = output_filename.strip_edges()

	if directory.is_empty():
		push_error("Select an output directory.")
		return ""

	if filename.is_empty():
		push_error("Enter an output filename.")
		return ""


	if filename.to_lower().ends_with(".png"):
		filename = filename.left(filename.length() - 4)

	filename = filename.validate_filename()

	if filename.is_empty():
		push_error("The output filename is invalid.")
		return ""

	directory = directory.replace("\\", "/")

	while directory.ends_with("/"):
		directory = directory.left(directory.length() - 1)

	return "%s/%s.png" % [directory, filename]


func _ensure_output_directory_exists() -> bool:
	var directory: String = output_directory.strip_edges()

	if directory.is_empty():
		push_error("Select an output directory.")
		return false

	directory = directory.replace("\\", "/")

	var absolute_directory: String = ProjectSettings.globalize_path(directory)
	var error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)

	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error(
			"Could not create output directory '%s'. Error code: %d"
			%[directory, error]
		)
		return false

	return true


func _restore_animation_state(
	original_update_mode: SubViewport.UpdateMode, 
	original_animation: StringName, 
	original_position: float, 
	original_playing: bool, 
	original_speed_scale: float
) -> void :
	render_target_update_mode = original_update_mode

	if is_instance_valid(animation_player):
		animation_player.speed_scale = original_speed_scale

		if (
			not original_animation.is_empty()
			and animation_player.has_animation(original_animation)
		):
			animation_player.play(original_animation)
			animation_player.seek(original_position, true)

			if original_playing:
				animation_player.play(original_animation)
				animation_player.seek(original_position, true)
			else:
				animation_player.pause()
		else:
			animation_player.stop()

	_is_capturing = false
