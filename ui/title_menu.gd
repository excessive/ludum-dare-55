extends Control

@export_file("*.tscn") var next_scene_path
@export var prev_scene: PackedScene
@onready var focus := SnailInput.get_input_focus(self)

func _physics_process(_delta: float) -> void:
	var _input := focus.get_player_input()

	if prev_scene and _input.is_action_just_pressed("ui_cancel"):
		SnailTransition.auto_transition(prev_scene)

func _ready():
	$play.grab_focus()
	$play.pressed.connect(_on_play)
	$qtd.pressed.connect(_on_quit)

func _on_play():
	SnailTransition.auto_transition_threaded(next_scene_path)

func _on_quit():
	SnailTransition.quit_after_transition_out = true
	SnailTransition.auto_transition(null)
