extends RigidBody3D

signal use(user: Node3D)
signal reset
signal control(user: Node3D, input: Vector3)

@export var thrust_force := 2500
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

func _closest_vector(b: Basis, v: Vector3) -> Vector3:
	var cmp := Vector3(b.x.dot(v), b.y.dot(v), b.z.dot(v))
	var axis := cmp.abs().max_axis_index()
	return b[axis] * signf(cmp[axis])

func _closest_alignment(from_basis: Basis, to_basis: Basis) -> Basis:
	var cx := _closest_vector(to_basis, from_basis.x)
	var cy := _closest_vector(to_basis, from_basis.y)
	return Basis(cx, cy, cx.cross(cy)).orthonormalized()

func _physics_process(delta: float) -> void:
	if active <= 0.0:
		return
	active -= delta
	var force := -global_basis.z * thrust_force * delta
	apply_central_force(force)
	#DD.draw_ray_3d(global_position, force.normalized(), 2, Color.RED)

	# DISABLED TO SHIP THIS GAME SORRY
	#var correction := Basis.looking_at(-get_viewport().get_camera_3d().global_basis.z)
	##var correction := Basis.looking_at(-global_basis.z * Vector3(1, 0, 1))
	#var av := (correction * global_basis.inverse()).get_euler()
	#apply_torque(av * thrust_force * 0.1 * delta)
