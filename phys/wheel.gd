extends RigidBody3D

signal use(user: Node3D)
signal reset

@export var torque := 1000
@export var active := 0.0

func _ready() -> void:
	use.connect(_on_use)
	reset.connect(_on_reset)

func _on_reset():
	active = 0.0

func _on_use(_user: Node3D):
	active = 10.0

func _physics_process(delta: float) -> void:
	if active <= 0.0:
		return
	active -= delta
	var force := -global_basis.x * torque * delta
	apply_torque(force)
