extends Node

var first_load := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
