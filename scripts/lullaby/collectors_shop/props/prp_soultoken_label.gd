extends Label3D


func _ready() -> void :
	text = str(SaveData.tokens)
	SaveData.tokens_changed.connect(_on_tokens_changed)


func _on_tokens_changed(count: int) -> void :
	text = str(count)
