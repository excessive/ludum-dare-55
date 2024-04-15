extends Button
class_name UnlockButton

@export var flag_name: String

func _ready() -> void:
	assert(flag_name)
	if Globals.check_flag(flag_name):
		disabled = false
	else:
		disabled = true
