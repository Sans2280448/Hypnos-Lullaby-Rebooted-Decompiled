@tool
extends Node3D
class_name Collector

@export var animation_player: AnimationPlayer
@export var idle_prefix: String = "pose_idle_"

@export_group("Lip Sync")
@export var lip_sync_enabled: bool = true
@export var voice_player: AudioStreamPlayer3D
@onready var skeleton: Skeleton3D = $Armature / Skeleton3D

@export var top_teeth_bone_name: String = "Teeth top"
@export var bottom_teeth_bone_name: String = "Teeth Bottom"

@export var top_open_position: Vector3 = Vector3(0.0, -0.03, 0.0)
@export var bottom_open_position: Vector3 = Vector3(0.0, 0.03, 0.0)

@export var top_open_rotation: Vector3 = Vector3(0.0, 0.0, 0.0)
@export var bottom_open_rotation: Vector3 = Vector3(0.0, 0.0, 0.0)

@export var top_open_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var bottom_open_scale: Vector3 = Vector3(1.0, 1.0, 1.0)

@export var lip_sync_strength: float = 0.665
@export var lip_sync_speed: float = 18.0

@export_group("Bus Lip Sync")
@export var voice_bus_name: StringName = &"Voice"
@export var spectrum_effect_index: int = 0
@export var min_frequency: float = 80.0
@export var max_frequency: float = 3000.0
@export var volume_floor_db: float = -55.0
@export var volume_ceiling_db: float = -12.0

@onready var smoke_particles: Node3D = $Armature / Skeleton3D / BoneAttachment3D / SmokeOffset / CollectorSmoke

var collector_idles: Array[String] = []
var last_collector_idle: String = ""

var top_teeth_bone_index: int = -1
var bottom_teeth_bone_index: int = -1

var top_closed_position: Vector3 = Vector3.ZERO
var bottom_closed_position: Vector3 = Vector3.ZERO

var top_closed_rotation: Quaternion = Quaternion.IDENTITY
var bottom_closed_rotation: Quaternion = Quaternion.IDENTITY

var top_closed_scale: Vector3 = Vector3.ONE
var bottom_closed_scale: Vector3 = Vector3.ONE

var mouth_amount: float = 0.0
var spectrum: AudioEffectSpectrumAnalyzerInstance

func _ready() -> void :
	refresh_idles()
	setup_bones()
	setup_spectrum_analyzer()

	play_random_idle()


func _process(delta: float) -> void :
	if skeleton == null:
		skeleton = get_node_or_null("Armature/Skeleton3D")

	if top_teeth_bone_index == -1 or bottom_teeth_bone_index == -1:
		setup_bones()

	update_lip_sync(delta)


func setup_bones() -> void :
	if skeleton == null:
		return

	top_teeth_bone_index = skeleton.find_bone(top_teeth_bone_name)
	bottom_teeth_bone_index = skeleton.find_bone(bottom_teeth_bone_name)

	if top_teeth_bone_index != -1:
		top_closed_position = skeleton.get_bone_pose_position(top_teeth_bone_index)
		top_closed_rotation = skeleton.get_bone_pose_rotation(top_teeth_bone_index)
		top_closed_scale = skeleton.get_bone_pose_scale(top_teeth_bone_index)
	else:
		push_warning("Could not find top teeth bone: " + top_teeth_bone_name)

	if bottom_teeth_bone_index != -1:
		bottom_closed_position = skeleton.get_bone_pose_position(bottom_teeth_bone_index)
		bottom_closed_rotation = skeleton.get_bone_pose_rotation(bottom_teeth_bone_index)
		bottom_closed_scale = skeleton.get_bone_pose_scale(bottom_teeth_bone_index)
	else:
		push_warning("Could not find bottom teeth bone: " + bottom_teeth_bone_name)


func setup_spectrum_analyzer() -> void :
	var bus_index: int = AudioServer.get_bus_index(voice_bus_name)

	if bus_index == -1:
		push_warning("Could not find audio bus: " + str(voice_bus_name))
		return

	var effect: AudioEffect = AudioServer.get_bus_effect(bus_index, spectrum_effect_index)

	if effect == null:
		push_warning("No audio effect found at index " + str(spectrum_effect_index))
		return

	if effect is not AudioEffectSpectrumAnalyzer:
		push_warning("Effect is not an AudioEffectSpectrumAnalyzer.")
		return

	spectrum = AudioServer.get_bus_effect_instance(bus_index, spectrum_effect_index) as AudioEffectSpectrumAnalyzerInstance


func refresh_idles() -> void :
	collector_idles.clear()

	if animation_player == null:
		return

	for anim_name: String in animation_player.get_animation_list():
		if anim_name.begins_with(idle_prefix):
			collector_idles.append(anim_name)


func get_idle() -> String:
	if collector_idles.is_empty():
		refresh_idles()

	if collector_idles.is_empty():
		return ""

	if collector_idles.size() == 1:
		return collector_idles[0]

	var possible_idles: Array[String] = collector_idles.duplicate()
	possible_idles.erase(last_collector_idle)

	return possible_idles.pick_random()


func play_random_idle() -> void :
	var idle_name: String = get_idle()

	if idle_name.is_empty():
		push_warning("No collector idle animations found with prefix: " + idle_prefix)
		return

	last_collector_idle = idle_name
	animation_player.play(idle_name)


func update_lip_sync(delta: float) -> void :
	var target: float = 0.0

	if lip_sync_enabled and voice_player != null and voice_player.playing and spectrum != null:
		var magnitude: Vector2 = spectrum.get_magnitude_for_frequency_range(
			min_frequency, 
			max_frequency, 
			AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX
		)

		var linear_volume: float = max(magnitude.x, magnitude.y)
		var volume_db: float = linear_to_db(linear_volume)

		target = inverse_lerp(volume_floor_db, volume_ceiling_db, volume_db)
		target = clamp(target * lip_sync_strength, 0.0, 1.0)

	mouth_amount = lerp(mouth_amount, target, 1.0 - exp( - lip_sync_speed * delta))

	if skeleton == null:
		return

	if top_teeth_bone_index != -1:
		var top_rotation_offset: Quaternion = Quaternion.from_euler(top_open_rotation * mouth_amount)

		skeleton.set_bone_pose_position(
			top_teeth_bone_index, 
			top_closed_position + (top_open_position * mouth_amount)
		)

		skeleton.set_bone_pose_rotation(
			top_teeth_bone_index, 
			top_closed_rotation * top_rotation_offset
		)

		skeleton.set_bone_pose_scale(
			top_teeth_bone_index, 
			top_closed_scale.lerp(top_open_scale, mouth_amount)
		)

	if bottom_teeth_bone_index != -1:
		var bottom_rotation_offset: Quaternion = Quaternion.from_euler(bottom_open_rotation * mouth_amount)

		skeleton.set_bone_pose_position(
			bottom_teeth_bone_index, 
			bottom_closed_position + (bottom_open_position * mouth_amount)
		)

		skeleton.set_bone_pose_rotation(
			bottom_teeth_bone_index, 
			bottom_closed_rotation * bottom_rotation_offset
		)

		skeleton.set_bone_pose_scale(
			bottom_teeth_bone_index, 
			bottom_closed_scale.lerp(bottom_open_scale, mouth_amount)
		)
