extends Generic6DOFJoint3D
class_name GlueJoint

var display := MeshInstance3D.new()

# used for safety detach and display
var reference_distance := 0.0

func _init(a: RigidBody3D, b: RigidBody3D) -> void:
	var cap := CapsuleMesh.new()
	reference_distance = a.global_position.distance_to(b.global_position)
	cap.height = reference_distance
	cap.radius = 0.1
	display.mesh = cap
	display.rotate_x(PI/2)
	add_child(display)
	node_a = a.get_path()
	node_b = b.get_path()

	# these _significantly_ increase the joint rigidity
	var pin := PinJoint3D.new()
	pin.node_a = node_a
	pin.node_b = node_b
	add_child(pin)

	var lock := HingeJoint3D.new()
	lock.node_a = node_a
	lock.node_b = node_b
	lock.set("angular_limit/enable", true)
	lock.set("angular_limit/lower_limit", 0)
	lock.set("angular_limit/upper_limit", 0)
	add_child(lock)

func _update_position():
	var a := get_node_or_null(node_a)
	var b := get_node_or_null(node_b)
	if not a or not b:
		return
	if a.global_position.distance_to(b.global_position) > reference_distance * 4:
		Contraption.detach_body(a)
		print("safety detach")
	var ab := a as RigidBody3D
	var bb := b as RigidBody3D
	var up: Vector3 = ab.global_basis.y
	var center := (ab.global_position + bb.global_position) / 2
	var dir := center.direction_to(bb.global_position)
	var angle := minf(dir.angle_to(up), dir.angle_to(-up))
	if angle < 0.01:
		up = ab.global_basis.z
	look_at_from_position(center, bb.global_position, up)

func _physics_process(_delta: float) -> void:
	_update_position()
