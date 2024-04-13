extends CharacterBody3D

@onready var focus := SnailInput.get_input_focus(self)

func _physics_process(_delta: float) -> void:
	var _input := focus.get_player_input()

