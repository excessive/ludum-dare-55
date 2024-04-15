extends Node
class_name SaveValue

@export var save_flag: String
@export var save_value: String

func _ready() -> void:
	if save_flag and not Globals.check_flag(save_flag):
		if OS.has_feature("editor"):
			print("set ", save_flag, " = ", save_value)
		Globals.flags[save_flag] = save_value
		Globals.save()
