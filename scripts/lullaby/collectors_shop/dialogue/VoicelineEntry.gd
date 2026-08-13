extends Resource
class_name VoicelineEntry

enum ShopStates{
	BUSY, 
	FREE_LOOK, 
	FOCUSED, 
}

@export var stream: AudioStream
@export_multiline var dialogue_text: String = ""

@export_enum("BUSY", "FREE_LOOK", "FOCUSED", "NONE")
var state: int = 1

@export_enum("BUSY", "FREE_LOOK", "FOCUSED", "NONE")
var ending_state: int = 2
