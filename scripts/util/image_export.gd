extends Node2D

const source_folder_path = "res://"
const destination_folder_path = "res://dumping"

const filenames = [
"./assets/funkin/monochrome/characters/blood/bf/chr_bfp3_tex_frames.tres",
"./assets/funkin/monochrome/characters/blood/bf/chr_bfp3_gunk_tex_frames.tres",
"./assets/funkin/monochrome/characters/blood/gold/chr_goldbl_tex_frames.tres",
"./assets/funkin/monochrome/characters/blood/gold/chr_goldbl_gunk_tex_frames.tres",
"./assets/funkin/monochrome/characters/goldp2/chr_goldp2_tex_frames.tres",
"./assets/funkin/monochrome/characters/smileychrome/chr_smileychrome_tex.tres",
"./assets/funkin/monochrome/cutscene/intro/anims/cut_mono_intro_celebi_frames.tres",
"./assets/funkin/monochrome/cutscene/intro/anims/cut_mono_intro_rise_frames.tres",
"./assets/funkin/monochrome/cutscene/intro/anims/cut_mono_intro_unown_front_frames.tres",
"./assets/funkin/monochrome/cutscene/intro/anims/cut_mono_intro_unown_frames.tres",
"./assets/funkin/monochrome/cutscene/pre_blood/cut_mono_pre_blood_frames.tres",
"./assets/funkin/monochrome/cutscene/cut_mono_collectorhand.tres",
"./assets/funkin/monochrome/cutscene/cut_boyfriend_scream.tres",
"./assets/funkin/monochrome/cutscene/cut_mono_looking_up.tres",
"./assets/funkin/monochrome/cutscene/cut_mono_white.tres",
"./assets/funkin/monochrome/cutscene/cut_mono_reachinghand.tres",
"./assets/funkin/monochrome/cutscene/cut_mono_closeup.tres",
"./assets/funkin/monochrome/cutscene/cut_mono_approach.tres",
"./assets/funkin/monochrome/cutscene/cut_mono_white_library.tres",
"./assets/funkin/monochrome/cutscene/cut_mono_blood.tres",
"./assets/funkin/monochrome/cutscene/cut_unowns_bg.tres",
"./assets/funkin/monochrome/cutscene/cut_unowns_fg.tres",
"./assets/funkin/monochrome/intro/tex_mono_unowns_intro_frames.tres",
"./assets/funkin/monochrome/mechanics/unown/tex_mch_unown_frames.tres",
"./assets/funkin/monochrome/pause/ui_monochrome_pause.tres",
"./assets/funkin/monochrome/stage/kingseye/tex_mono_kingseye_frames.tres",
"./assets/funkin/monochrome/stage/pulse/tex_mono_pulse_frames.tres",
"./assets/funkin/monochrome/ui/notes/nte_mono.tres",
"./assets/funkin/monochrome/ui/health/health.tres"
]

var tres_array = []
var saved = false

func _ready():
	for filename in filenames:
		var tres = load(source_folder_path + filename)
		print("Loading ", tres)
		tres_array.append(tres)

func _process(_delta):
	if tres_array == null:
		return
	if tres_array[filenames.size() - 1] == null:
		return
	if saved == false:
		for tres in tres_array:
			var resource_name = tres.resource_path.trim_prefix(source_folder_path)
			var filename = resource_name + ".png"
			print("Saving %s..." % filename)
			var img = tres.get_image()
			img.clear_mipmaps()
			var _x = img.save_png(destination_folder_path + filename)
			print("Saved.")
		saved = true
		print("Done.")

func _on_dump_stuff_pressed() -> void:
	_ready() # the finale?
