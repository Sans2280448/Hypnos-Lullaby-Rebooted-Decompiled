// Contrast effects on a canvas item
// Look in code for credits
// Shader by lunarcleint, your good to use this on anything without credit

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;

uniform float CONTRAST : hint_range(0.0, 2.0);

// Function from: https://tsev.dev/posts/2020-06-19-colour-correction-with-webgl/
vec3 adjustContrast(vec3 color, float value) {
  return 0.5 + value * (color - 0.5);
}

void fragment() {
	vec4 SCREEN_PIXEL = texture(SCREEN_TEXTURE, SCREEN_UV);
	SCREEN_PIXEL.rgb = adjustContrast(SCREEN_PIXEL.rgb, CONTRAST);
	COLOR = SCREEN_PIXEL;
}