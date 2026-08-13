shader_type canvas_item;

uniform sampler2D screen_tex: hint_screen_texture;

uniform float amount: hint_range(0.0, 1.0, 0.01) = .2;

uniform float speed: hint_range(.1, 5., 0.1) = 1.0;

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}


void fragment() {
	
	vec2 uv = vec2(UV.x + TIME * speed, UV.y + TIME * speed);
	
	vec4 screen = texture(screen_tex, SCREEN_UV);
	
	
	
	vec4 noise = vec4(random(uv), random(uv), random(uv), 1.0);
	
	COLOR = screen * vec4(noise.r, noise.g, noise.b, amount);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
