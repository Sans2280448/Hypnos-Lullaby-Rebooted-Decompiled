shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_test_disabled;

uniform sampler2D depth_texture : hint_depth_texture;
uniform vec3 color : source_color = vec3(1.0, 0.0, 0.0);
uniform float density = 1.0;

void fragment() {
	// Distance from depth buffer
	vec3 scene_clip_pos = vec3(SCREEN_UV * 2.0 - 1.0, texture(depth_texture, SCREEN_UV).r);
	vec4 scene_view_pos = INV_PROJECTION_MATRIX * vec4(scene_clip_pos, 1.0);
	scene_view_pos.xyz /= scene_view_pos.w;
	float scene_dist = length(scene_view_pos.xyz);
	
	// Distance to mesh
	float dist = length(VERTEX);
	
	// Add distance for back faces and subtract for front, checking against the depth buffer in each case
	if (!FRONT_FACING) {
		dist = min(dist, scene_dist);
	}
	else {
		dist = -dist;
		dist = max(dist, -scene_dist);
	}
    ALBEDO = dist * color * density;
}