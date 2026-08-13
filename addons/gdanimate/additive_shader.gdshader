shader_type canvas_item;
render_mode blend_add;

instance uniform vec4 color_multipliers = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform vec4 color_offsets = vec4(0.0);

instance uniform int blend_mode : hint_enum(
	"ADD",
	"ALPHA", // Not implemented, just per Flash n' stuff
	"DARKEN",
	"DIFFERENCE",
	"ERASE", // Not implemented, just per Flash n' stuff
	"HARD LIGHT",
	"INVERT",
	"LAYER", // Not implemented, just per Flash n' stuff
	"LIGHTEN",
	"MULTIPLY",
	"NORMAL",
	"OVERLAY",
	"SCREEN",
	"SHADER", // Not implemented, just per Flash n' stuff
	"SUBTRACT"
) = 0;

void fragment() {
	COLOR = color_offsets + (COLOR * color_multipliers);
}
