extends RigidBody3D

signal control(user: Node3D, global_reference: Transform3D, input: Vector3)

@export var rotation_force := 100

func _ready() -> void:
	control.connect(_on_control)

func calc_angular_velocity(from_basis: Basis, to_basis: Basis) -> Vector3:
	return (to_basis * from_basis.inverse()).get_euler()

func _align_to_forward(forward: Vector3, up: Vector3) -> Basis:
	if forward.is_zero_approx(): # prevent zero forward vector
		forward -= global_basis.z * 0.001
	return Basis(
		forward.cross(up).normalized(),
		up,
		-forward.normalized()
	).orthonormalized()

func _on_control(_user: Node3D, _global_reference: Transform3D, _input: Vector3):
	var bodies := Contraption.get_all_bodies(self)
	var total_mass := 0.0
	for body in bodies:
		total_mass += body.mass

	var vp := get_viewport()
	var center := vp.get_visible_rect().get_center()
	var looking_at := vp.get_camera_3d().project_ray_normal(center)
	looking_at = looking_at.lerp(-global_basis.z, 0.25)
	#looking_at = global_basis.z
	var target_basis := Basis(
		Vector3.UP.cross(looking_at),
		Vector3.UP,
		looking_at,
	).orthonormalized()
	target_basis = Basis.looking_at(looking_at)
	var av := calc_angular_velocity(global_basis, target_basis)
	#av *= total_mass
	av *= 50
	apply_torque(av)

func _closest_vector(b: Basis, v: Vector3) -> Vector3:
	var cmp := Vector3(b.x.dot(v), b.y.dot(v), b.z.dot(v))
	var axis := cmp.abs().max_axis_index()
	return b[axis] * signf(cmp[axis])

func _closest_alignment(from_basis: Basis, to_basis: Basis) -> Basis:
	var cx := _closest_vector(to_basis, from_basis.x)
	var cy := _closest_vector(to_basis, from_basis.y)
	return Basis(cx, cy, cx.cross(cy)).orthonormalized()
