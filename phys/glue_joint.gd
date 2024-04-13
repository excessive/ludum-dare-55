extends Generic6DOFJoint3D
class_name GlueJoint

var display := MeshInstance3D.new()

func _init(a: RigidBody3D, b: RigidBody3D) -> void:
	var cap := CapsuleMesh.new()
	cap.height = a.global_position.distance_to(b.global_position)
	cap.radius = 0.1
	display.mesh = cap
	display.rotate_x(PI/2)
	add_child(display)
	node_a = a.get_path()
	node_b = b.get_path()

func _update_position():
	var a := get_node_or_null(node_a)
	var b := get_node_or_null(node_b)
	if not a or not b:
		return
	look_at_from_position((a.global_position + b.global_position) / 2, b.global_position)

func _ready() -> void:
	_update_position()

func _physics_process(_delta: float) -> void:
	_update_position()
