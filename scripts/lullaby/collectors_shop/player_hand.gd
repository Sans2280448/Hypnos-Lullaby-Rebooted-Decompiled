extends Node3D

@export var base_pos: Vector3 = Vector3.ZERO
@export var camera: RubiconInterpolatedCamera3D
@export var shop: CollectorShop

func _process(delta: float) -> void :
	var elapsed_time: float = Time.get_ticks_msec() / 1000.0;

	var sined_pos: Vector3 = Vector3(base_pos)
	if shop.state == shop.ShopStates.FREE_LOOK:
		sined_pos.x += (sin(elapsed_time) * 0.002) + sin(elapsed_time * 0.25) * 0.002 * 0.15
		sined_pos.y += cos(elapsed_time + (PI / 2)) * 0.001 + cos(elapsed_time * 0.25) * 0.005 * 0.15

	position = lerp(position, sined_pos, 1.0 - pow(0.0003, delta))
