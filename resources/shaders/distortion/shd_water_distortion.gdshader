// Simulate water like effects on a canvas item
// Shader by lunarcleint, your good to use this on anything without credit
// Remastered waterDistortion.frag (https://github.com/lunarcleint/dustin-mod/blob/master/shaders/waterDistortion.frag)

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform sampler2D NOISE_TEXTURE : source_color, repeat_enable, filter_linear;

uniform float WAVE_STRENGTH : hint_range(0.0, 2.0);
uniform float GHOST_STRENGTH :  hint_range(0.0, 1.0);

void fragment() {
	vec4 WAVY_COLOR = vec4(1.0);
	
	if (WAVE_STRENGTH <= 0.0) {
		WAVY_COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	} else {
		vec2 NOISE_SAMPLE_UV = SCREEN_UV * vec2(3.0, 1.0);
		
		NOISE_SAMPLE_UV.x -= TIME * 0.15;
		
		// Flip texture every other repeat for looping
		float NOISE_INDEX = floor(NOISE_SAMPLE_UV.x);
		bool INDEX_IS_ODD = mod(NOISE_INDEX, 2.0) != 0.0;
		
		vec2 NOISE_LOCAL_UV = fract(NOISE_SAMPLE_UV);
		
		if (INDEX_IS_ODD) {
			NOISE_LOCAL_UV.x = 1.0 - NOISE_LOCAL_UV.x;
		}
		
		vec4 NOISE = texture(NOISE_TEXTURE, NOISE_LOCAL_UV);
		
		vec2 OFFSET = NOISE.xy * WAVE_STRENGTH * 0.0125;
		
		WAVY_COLOR = texture(SCREEN_TEXTURE, (SCREEN_UV + OFFSET));
		
		/*
		WAVY_COLOR.r = texture(SCREEN_TEXTURE, (SCREEN_UV + OFFSET) + (vec2(-0.01, 0.01) * OFFSET)).r;
		WAVY_COLOR.g = texture(SCREEN_TEXTURE, (SCREEN_UV + OFFSET) + (vec2(0.01, 0.01) * OFFSET)).g;
		WAVY_COLOR.b = texture(SCREEN_TEXTURE, (SCREEN_UV + OFFSET) + (vec2(-0.01, 0.01) * OFFSET)).b;
		*/
		
		WAVY_COLOR += texture(SCREEN_TEXTURE, SCREEN_UV + (OFFSET * (1.0 - GHOST_STRENGTH)));
		// Average out the two to not scrotch my eyes
		WAVY_COLOR *= 0.5;	
	}
	
	COLOR = WAVY_COLOR;
}