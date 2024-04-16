extends Button
class_name UnlockButton

@export var flag_name: String

func _ready() -> void:
	assert(flag_name)
	if Globals.check_flag(flag_name):
		_on_new_unlock(flag_name)
		Globals.new_unlock.connect(_on_new_unlock)
	else:
		Globals.new_unlock.connect(_on_new_unlock)

func _on_new_unlock(flag: String):
	if flag_name != flag:
		return

	if Globals.check_flag(flag_name):
		disabled = false
	else:
		disabled = true
