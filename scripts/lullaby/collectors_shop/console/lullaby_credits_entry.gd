extends Resource
class_name LullabyCreditsEntry

@export var name: String
@export var role: String
@export_multiline() var description: String
@export var socials_link: String

func empty():
	name = "empty"
	role = ""
	description = ""
	socials_link = ""
