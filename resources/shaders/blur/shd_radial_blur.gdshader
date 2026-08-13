shader_type canvas_item;

// Ported from: https://www.shadertoy.com/view/XsfSDs
// Shader ported by lunarcleint, open to use (credit shadertoy link)

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;

uniform float BLUR_STRENGTH;
uniform vec2 BLUR_CENTER;

const int SAMPLES = 15;

void fragment() {
	vec2 BLUR_UV = SCREEN_UV - BLUR_CENTER;
	vec4 BLUR_COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	float PRECOMPUTE = BLUR_STRENGTH * 0.1 * (1.0 / float(SAMPLES - 1));
	for(int i = 1; i < SAMPLES; i++) {
	    float SCALE = 1.0 + (float(i) * PRECOMPUTE);
	    BLUR_COLOR += texture(SCREEN_TEXTURE, BLUR_UV * SCALE + BLUR_CENTER);
	}
	BLUR_COLOR /= float(SAMPLES);
	
	COLOR = BLUR_COLOR;
}
