@tool
extends Node

const RED_PARAMETER: StringName = &"r"
const GREEN_PARAMETER: StringName = &"g"
const BLUE_PARAMETER: StringName = &"b"

@export var shader_material: ShaderMaterial
@export var color_r: Color = Color.RED:
	get:
		return shader_material.get_shader_parameter(RED_PARAMETER)
	set(val):
		shader_material.set_shader_parameter(RED_PARAMETER, val)

@export var color_g: Color = Color.GREEN:
	get:
		return shader_material.get_shader_parameter(GREEN_PARAMETER)
	set(val):
		shader_material.set_shader_parameter(GREEN_PARAMETER, val)

@export var color_b: Color = Color.BLUE:
	get:
		return shader_material.get_shader_parameter(BLUE_PARAMETER)
	set(val):
		shader_material.set_shader_parameter(BLUE_PARAMETER, val)
