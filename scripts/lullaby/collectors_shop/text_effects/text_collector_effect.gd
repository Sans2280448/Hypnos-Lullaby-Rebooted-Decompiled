extends RichTextEffect
class_name CollectorEffect

@export var bbcode: = "collector"

@export var jingle: AudioStream
@export var volume_db: float = 0.0
@export var bus: StringName = &"Master"

@export var shake_rate: float = 20.0
@export var shake_level: float = 1.0
@export var text_color: Color = Color.YELLOW

var _played_ranges: Dictionary = {}

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.color = text_color

	var time: = char_fx.elapsed_time * shake_rate
	var offset_x: = sin(time + char_fx.relative_index * 1.7) * shake_level
	var offset_y: = cos(time + char_fx.relative_index * 2.3) * shake_level

	char_fx.transform = char_fx.transform.translated(Vector2(offset_x, offset_y))

	if char_fx.relative_index == 0:
		jingle_sound(char_fx)

	return true


func jingle_sound(char_fx: CharFXTransform) -> void :
	if jingle == null:
		return

	var key: = str(char_fx.range)

	if _played_ranges.has(key):
		return

	_played_ranges[key] = true

	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return

	var player: = AudioStreamPlayer.new()
	player.name = "CollectorJingle"
	player.stream = jingle
	player.volume_db = volume_db
	player.bus = bus

	tree.root.add_child.call_deferred(player)
	player.play.call_deferred()

	player.finished.connect( func() -> void :
		player.queue_free()
	)
