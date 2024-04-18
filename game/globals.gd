extends Node

var first_load := true
var flags: Dictionary = {}

const SAVE_FILE := "user://save.json"

signal new_unlock(flag: String)

func check_flag(flag: String) -> bool:
	return flags.has(flag) and flags[flag]

func set_flag(flag: String, value := true):
	flags[flag] = value
	new_unlock.emit(flag)
	print("set %s=%s" % [flag, value])

func restart():
	if OS.has_feature("editor"): # restart doesn't work in editor
		print("can't restart in editor, only in exports")
		return

	var args := OS.get_cmdline_args()
	if check_flag("mobile"):
		var mobile := ["--rendering-method", "mobile"]
		if not args.has("--rendering-method"):
			args.append_array(mobile)
	OS.set_restart_on_exit(true, args)
	get_tree().quit()

func _enter_tree() -> void:
	var args := OS.get_cmdline_args()
	if check_flag("mobile") and not args.has("--rendering-method"):
		restart()

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
