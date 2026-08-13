// HSV effects on a canvas item
// Look in code for credits
// Shader by lunarcleint, your good to use this on anything without credit

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;

uniform float HUE : hint_range(0.0, 360.0);
uniform float SATURATION : hint_range(0.0, 3.0);
uniform float VALUE : hint_range(0.0, 1.0);

// Functions from: https://gamedev.stackexchange.com/questions/59797/glsl-shader-change-hue-saturation-brightness
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 SCREEN_PIXEL = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	vec3 HSV = rgb2hsv(SCREEN_PIXEL.rgb);
	HSV.x *= (360.0 - HUE) / 360.0;
	HSV.y *= SATURATION;
	HSV.z *= VALUE;
	
	SCREEN_PIXEL.rgb = hsv2rgb(HSV);
	COLOR = SCREEN_PIXEL;
}