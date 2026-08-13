extends Label

@export var timer: Timer

func _ready() -> void :
	update_time()
	timer.start()

func update_time() -> void :
	var time = Time.get_datetime_dict_from_system();

	var hour: int = time["hour"]
	var minute: int = time["minute"]
	var day: int = time["day"]
	var month: int = time["month"]

	var ampm: String = "am"
	if hour >= 12:
		ampm = "pm"
		if hour > 12:
			hour -= 12
	if hour == 0:
		hour = 12

	var month_names: Array[String] = ["Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", 
		"Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."]
	var month_name = month_names[month - 1]

	text = "%02d:%02d%s | %s %02d" % [hour, minute, ampm, month_name, day]
