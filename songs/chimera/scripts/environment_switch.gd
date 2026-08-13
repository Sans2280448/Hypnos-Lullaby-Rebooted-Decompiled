@tool
extends WorldEnvironment

@export var colors: PackedColorArray:
	get():
		if environment != null:
			var cc: Texture = environment.adjustment_color_correction
			if cc is GradientTexture1D:
				_colors = cc.gradient.colors
				return _colors
		return []
	set(value):
		if _colors == value:
			return
		_colors = value
		_set_gradient_colors(value)
var _colors: PackedColorArray

@export var offsets: PackedFloat32Array:
	get():
		if environment != null:
			var cc: Texture = environment.adjustment_color_correction
			if cc is GradientTexture1D:
				_offsets = cc.gradient.offsets
				return _offsets
		return []
	set(value):
		if _offsets == value:
			return
		_offsets = value
		_set_gradient_offsets(value)
var _offsets: PackedFloat32Array

func _set_gradient_colors(value: PackedColorArray) -> void :
	if environment != null:
		var cc: Texture = environment.adjustment_color_correction
		if cc is GradientTexture1D:
			cc.gradient.colors = value

func _set_gradient_offsets(value: PackedFloat32Array) -> void :
	if environment != null:
		var cc: Texture = environment.adjustment_color_correction
		if cc is GradientTexture1D:
			cc.gradient.offsets = value
