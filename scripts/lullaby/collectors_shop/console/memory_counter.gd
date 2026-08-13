extends Label


const BASE_MEM: float = 0.2

var mem: float = BASE_MEM:
	set(v):
		if mem != v:
			mem = v
			text = "%.2f TB Memory" % mem

var next_max: float
var speed: float
var flip: bool = false


func _ready() -> void :
	next_max = randf_range(1.1, 1.5)
	speed = randf_range(0.007, 0.02)


func _process(delta: float) -> void :
	if flip:
		mem -= delta * speed * 2.0
	else:
		mem += delta * speed * 2.0

	speed = clampf(speed + delta * randf_range(0.001, 0.003), 0.0, 0.05)

	if (mem >= next_max and not flip) or (mem < BASE_MEM and flip):
		if randf_range(0.0, 1.0) < 0.25:
			flip = not flip
		else:
			if mem < BASE_MEM and flip:
				mem = BASE_MEM
			else:
				mem -= randf_range(0.3, mem - BASE_MEM)

			flip = false
			next_max = randf_range(1.1, 1.5)
			speed = randf_range(0.007, 0.02)
