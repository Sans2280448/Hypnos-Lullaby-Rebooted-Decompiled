shader_type spatial;
render_mode unshaded, blend_add;

group_uniforms Color;
uniform vec3 primary_color : source_color = vec3(1.0);
uniform vec3 secondary_color : source_color = vec3(1.0, 0.8, 0.4);
uniform float emission = 2.0;
uniform float emission_mult = 1.0;

group_uniforms Shape;
uniform float streaks1_count = 5.0;
uniform float streaks2_count = 11.0;
uniform float streaks_fade : hint_range(-2.0, 2.0, 0.01) = 0.4;
uniform float streaks_thickness : hint_range(0.0, 4.0, 0.01) = 0.5;
uniform float center_radius : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float fade_radius : hint_range(0.0, 1.0, 0.01) = 0.4;

group_uniforms Connected_Streaks;
uniform bool connected_streaks = false;

/*
	How strongly the empty spaces are filled.

	0.0 = original separated streaks
	1.0 = completely connected shape
*/
uniform float connection_strength : hint_range(0.0, 1.0, 0.01) = 0.35;

/*
	Controls the brightness/thickness of the connecting material.
*/
uniform float connection_brightness : hint_range(0.0, 1.0, 0.01) = 0.25;

/*
	Higher values keep more definition between the individual streaks.
	Lower values produce a smoother solid ring.
*/
uniform float connection_sharpness : hint_range(0.1, 8.0, 0.01) = 2.0;

group_uniforms Alpha;
uniform bool proximity_fade = false;
uniform float proximity_fade_distance : hint_range(0.0, 8.0, 0.1) = 0.5;

uniform sampler2D depth_texture
	: hint_depth_texture, repeat_disable, filter_nearest;

group_uniforms Billboard;
uniform bool billboard = false;


float overlay(float base, float blend) {
	float limit = step(0.5, base);

	return mix(
		2.0 * base * blend,
		1.0 - 2.0 * (1.0 - base) * (1.0 - blend),
		limit
	);
}


void vertex() {
	if (billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]
		);
	}
}


void fragment() {
	vec2 centered_uv = UV - 0.5;

	float angle = atan(centered_uv.x, centered_uv.y);
	float radius = length(centered_uv) * 2.0;

	float view_offset = NORMAL.x * 0.5 + 0.5;

	if (NORMAL.z > 0.0) {
		view_offset = 1.0 - view_offset;
	}

	view_offset *= TAU;

	float streaks1 = sin(
		angle * streaks1_count
		+ view_offset
		+ TIME
	);

	float streaks2 = sin(
		angle * streaks2_count
		- view_offset
		- TIME
	);

	/*
		Convert the sine waves from -1..1 into 0..1 before
		combining them. This makes the shape more predictable.
	*/
	streaks1 = streaks1 * 0.5 + 0.5;
	streaks2 = streaks2 * 0.5 + 0.5;

	float value = overlay(streaks1, streaks2);

	value -= (1.0 - radius) * streaks_fade;
	value *= 1.0 - (radius - value * streaks_thickness);

	float outer_mask = max(1.0 - radius, 0.0);

	value *= outer_mask;
	value = min(value, outer_mask);

	value = smoothstep(0.1, 1.0, value);

	/*
		Fades the effect out around the center hole.
		The small denominator guard prevents division by zero
		when both radii are equal.
	*/
	float radius_difference = max(
		fade_radius - center_radius,
		0.0001
	);

	float center_mask = clamp(
		(radius - center_radius) / radius_difference,
		0.0,
		1.0
	);

	center_mask = pow(center_mask, 4.0);
	value *= center_mask;

	/*
		Connected mode creates a softer base shape beneath the
		individual streaks. The original streak value is kept,
		so their brighter tips and details remain visible.
	*/
	if (connected_streaks) {
		float connection_mask = outer_mask * center_mask;

		connection_mask = pow(
			max(connection_mask, 0.0),
			connection_sharpness
		);

		float connected_value =
			connection_mask
			* connection_brightness
			* connection_strength;

		value = max(value, connected_value);
	}

	vec3 final_color = mix(
		secondary_color,
		primary_color,
		value
	);

	ALBEDO =
		final_color
		* COLOR.rgb
		* emission
		* emission_mult;

	ALPHA = value * COLOR.a;

	// Proximity Fade
	if (proximity_fade) {
		float proximity_depth_tex = textureLod(
			depth_texture,
			SCREEN_UV,
			0.0
		).r;

		vec4 ndc;

		if (OUTPUT_IS_SRGB) {
			ndc = vec4(
				vec3(SCREEN_UV, proximity_depth_tex)
				* 2.0 - 1.0,
				1.0
			);
		} else {
			ndc = vec4(
				SCREEN_UV * 2.0 - 1.0,
				proximity_depth_tex,
				1.0
			);
		}

		vec4 proximity_view_pos =
			INV_PROJECTION_MATRIX * ndc;

		proximity_view_pos.xyz /=
			proximity_view_pos.w;

		ALPHA *= clamp(
			1.0 - smoothstep(
				proximity_view_pos.z
					+ proximity_fade_distance,
				proximity_view_pos.z,
				VERTEX.z
			),
			0.0,
			1.0
		);
	}
}