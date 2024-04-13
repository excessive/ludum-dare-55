extends RigidBody3D

signal use(user: Node3D)
signal reset

var thrust_force := 1000
var active := false

func _ready() -> void:
	use.connect(_on_use)
	reset.connect(_on_reset)

func _on_reset():
	active = false

func _on_use(_user: Node3D):
	active = not active

func _physics_process(delta: float) -> void:
	if not active:
		return
	var force := -global_basis.z * thrust_force * delta
	apply_central_force(force)
