extends Control

@export_file("*.tscn") var play_scene_path
@export_file("*.tscn") var sandbox_scene_path
@export var prev_scene: PackedScene
@onready var focus := SnailInput.get_input_focus(self)

func _physics_process(_delta: float) -> void:
	var input := focus.get_player_input()

	if prev_scene and input.is_action_just_pressed("ui_cancel"):
		SnailTransition.auto_transition(prev_scene)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _ready():
	$play.grab_focus()
	$play.pressed.connect(_on_play)
	$sandbox.pressed.connect(_on_sandbox)
	$clear.pressed.connect(_on_delete)
	$qtd.pressed.connect(_on_quit)

func _on_sandbox():
	SnailTransition.auto_transition_threaded(sandbox_scene_path)

func _on_play():
	SnailTransition.auto_transition_threaded(play_scene_path)

func _on_delete():
	Globals.clear_save()
	SnailTransition.auto_transition_threaded(scene_file_path)

func _on_quit():
	SnailTransition.quit_after_transition_out = true
	SnailTransition.auto_transition(null)
