extends RigidBody3D

signal use(user: Node3D)
signal reset
signal control(user: Node3D, input: Vector3)

@export var thrust_force := 1250
@export var active := 0.0

func _ready() -> void:
	use.connect(_on_use)
	reset.connect(_on_reset)
	control.connect(_on_control)

func _on_reset():
	active = 0.0

func _on_use(_user: Node3D):
	active = 10.0

func _on_control(_user: Node3D, input: Vector3):
	active = get_physics_process_delta_time() * input.limit_length().length()

func _physics_process(delta: float) -> void:
	if active <= 0.0:
		return
	active -= delta
	var force := -global_basis.z * thrust_force * delta
	apply_central_force(force)
