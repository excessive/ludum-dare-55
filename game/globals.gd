extends Node

var first_load := true
var flags: Dictionary = {}

const SAVE_FILE := "user://save.json"

func check_flag(flag: String) -> bool:
	return flags.has(flag) and flags[flag]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var save_data := FileAccess.get_file_as_string(SAVE_FILE)
	if save_data:
		flags = JSON.parse_string(save_data)
		print("loaded")
	else:
		print("new save data")

func clear_save():
	print("clearing save data")
	flags.clear()
	save()

func save():
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(flags, "\t"))
	print("saved")

func _exit_tree() -> void:
	save()
