extends ConsoleHomeButton


@export var bag_area: FocusArea3D
@export var handler: CartridgeBagHandler


@onready var label: Label = $Label
@onready var bind_label: Label = $BindLabel

var bind_fade_speed: float = 10.0
var _bind_target_alpha: float = 0.0


func _ready() -> void :
	super ()

	update_cartridge(SaveData.cartridge_selected)
	SaveData.new_cartridge_selected.connect(update_cartridge)

	_bind_target_alpha = 0.0
	bind_label.modulate.a = 0.0
	bind_label.visible = true


func _process(delta: float) -> void :
	bind_label.modulate.a = lerpf(
		bind_label.modulate.a, 
		_bind_target_alpha, 
		1.0 - exp( - bind_fade_speed * delta)
	)

	if absf(bind_label.modulate.a - _bind_target_alpha) < 0.001:
		bind_label.modulate.a = _bind_target_alpha

func _focus_entered() -> void :
	super ()
	_bind_target_alpha = 1.0


func _focus_exited() -> void :
	super ()
	_bind_target_alpha = 0.0


func _input(event: InputEvent) -> void :
	super (event)

	if disabled:
		return

	if event.is_action_released(&"open_cartridge_bag") and focused:
		if handler:
			handler.coming_from_console = true

		if console:
			console.back_out()

		if bag_area:
			bag_area.can_interact = true
			bag_area.trigger()
			bag_area.register_trigger()


func update_cartridge(cart: StringName) -> void :
	match cart:
		&"safety_lullaby":
			label.text = "Safety Lullaby"

		_:
			label.text = cart.to_pascal_case()
