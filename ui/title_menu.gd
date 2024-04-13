extends Control

@export var prev_scene: PackedScene
@onready var focus := SnailInput.get_input_focus(self)

# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	var _input := focus.get_player_input()
	DD.set_text("Input X", _input.get_axis("ui_left", "ui_right"))
	DD.set_text("Input Y", _input.get_axis("ui_down", "ui_up"))
	DD.set_text("A", _input.is_action_pressed("ui_accept"))
	DD.set_text("B", _input.is_action_pressed("ui_cancel"))

	if prev_scene and _input.is_action_just_pressed("ui_cancel"):
		SnailTransition.auto_transition(prev_scene)
