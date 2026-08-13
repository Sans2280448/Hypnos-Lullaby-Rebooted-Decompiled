class_name LullabyQualityPreset extends Resource

@export var name: String = "Default"

@export var scaling_3d_mode: Viewport.Scaling3DMode = Viewport.Scaling3DMode.SCALING_3D_MODE_BILINEAR
@export var positional_shadow_atlas_size: int = 4096
@export var positional_shadow_filter_quality: int = 2
@export var msaa_3d_quality: Viewport.MSAA = Viewport.MSAA.MSAA_DISABLED
@export var screen_space_aa_quality: Viewport.ScreenSpaceAA = Viewport.ScreenSpaceAA.SCREEN_SPACE_AA_SMAA
@export var post_processing: LullabySettings.PostProcessing = LullabySettings.PostProcessing.HIGH
@export var ssao: bool = true
@export var ssil: bool = true

func is_matching(settings: LullabySettings) -> bool:
	return (settings.graphics_scaling_mode == scaling_3d_mode and 
		settings.graphics_positional_shadow_atlas_size == positional_shadow_atlas_size and 
		settings.graphics_positional_shadow_filter_quality == positional_shadow_filter_quality and 
		settings.graphics_msaa_3d_quality == msaa_3d_quality and 
		settings.graphics_screen_space_aa_quality == screen_space_aa_quality and 
		settings.graphics_post_processing == post_processing and 
		settings.graphics_ssao == ssao and 
		settings.graphics_ssil == ssil
	)

func apply(settings: LullabySettings) -> void :
	settings.graphics_scaling_mode = scaling_3d_mode
	settings.graphics_positional_shadow_atlas_size = positional_shadow_atlas_size
	settings.graphics_positional_shadow_filter_quality = positional_shadow_filter_quality
	settings.graphics_msaa_3d_quality = msaa_3d_quality
	settings.graphics_screen_space_aa_quality = screen_space_aa_quality
	settings.graphics_post_processing = post_processing
	settings.graphics_ssao = ssao
	settings.graphics_ssil = ssil
