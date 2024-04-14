extends Generic6DOFJoint3D
class_name GlueJoint

var display := MeshInstance3D.new()

@export var linear_limit_enabled := true
@export var linear_spring_enabled := true
#@export var linear_motor_enabled := false

#@export var angular_limit_enabled := true
#@export var angular_motor_enabled := false
#@export var angular_spring_enabled := false

# set to the equilibrium point
#@export var linear_limit_lower_distance := 0.0
#@export var linear_limit_upper_distance := 0.0
@export var linear_limit_restitution := 2.0 # 0.5
@export var linear_limit_softness := 0.99 # 0.7
@export var linear_limit_damping := 1.75 # 1.0

@export var linear_spring_damping := 0.95
@export var linear_spring_equilibrium_point := 0.0
@export var linear_spring_stiffness := 10.0 # 0.01

#@export var linear_motor_force_limit := 0.0
#@export var linear_motor_target_velocity := 0.0

#@export var angular_spring_equilibrium_point := 0.0
#@export var angular_spring_stiffness := 0.0
#@export var angular_motor_force_limit := 300.0
#@export var angular_motor_target_velocity := 0.0
#@export var angular_spring_damping := 0.0

#@export var angular_limit_erp := 0.5
#@export var angular_limit_force_limit := 0.0
#@export var angular_limit_lower_angle := 0.0
#@export var angular_limit_restitution := 0.0
#@export var angular_limit_softness := 0.5
#@export var angular_limit_upper_angle := 0.0
#@export var angular_limit_damping := 1.0

func _init(a: RigidBody3D, b: RigidBody3D) -> void:
	var cap := CapsuleMesh.new()
	cap.height = a.global_position.distance_to(b.global_position)
	cap.radius = 0.1
	display.mesh = cap
	display.rotate_x(PI/2)
	add_child(display)
	node_a = a.get_path()
	node_b = b.get_path()
	exclude_nodes_from_collision = false

func _update_position():
	var a := get_node_or_null(node_a)
	var b := get_node_or_null(node_b)
	if not a or not b:
		return
	if a.global_position.distance_to(b.global_position) > linear_spring_equilibrium_point * 4:
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

func _ready() -> void:
	_update_position()

func _update_params():
	set_flag_x(FLAG_ENABLE_LINEAR_LIMIT, linear_limit_enabled)
	set_flag_y(FLAG_ENABLE_LINEAR_LIMIT, linear_limit_enabled)
	set_flag_z(FLAG_ENABLE_LINEAR_LIMIT, linear_limit_enabled)

	set_flag_x(FLAG_ENABLE_LINEAR_SPRING, linear_spring_enabled)
	set_flag_y(FLAG_ENABLE_LINEAR_SPRING, linear_spring_enabled)
	set_flag_z(FLAG_ENABLE_LINEAR_SPRING, linear_spring_enabled)

	#set_flag_x(FLAG_ENABLE_ANGULAR_LIMIT, angular_limit_enabled)
	#set_flag_y(FLAG_ENABLE_ANGULAR_LIMIT, angular_limit_enabled)
	#set_flag_z(FLAG_ENABLE_ANGULAR_LIMIT, angular_limit_enabled)

	var linear_limit_lower_distance := linear_spring_equilibrium_point
	var linear_limit_upper_distance := linear_spring_equilibrium_point
	set_param_x(PARAM_LINEAR_LOWER_LIMIT, linear_limit_lower_distance)
	set_param_x(PARAM_LINEAR_UPPER_LIMIT, linear_limit_upper_distance)
	set_param_x(PARAM_LINEAR_RESTITUTION, linear_limit_restitution)
	set_param_x(PARAM_LINEAR_LIMIT_SOFTNESS, linear_limit_softness)
	set_param_x(PARAM_LINEAR_DAMPING, linear_limit_damping)
	set_param_x(PARAM_LINEAR_SPRING_DAMPING, linear_spring_damping)
	set_param_x(PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT, linear_spring_equilibrium_point)
	set_param_x(PARAM_LINEAR_SPRING_STIFFNESS, linear_spring_stiffness)
	#set_param_x(PARAM_ANGULAR_ERP, angular_limit_erp)
	#set_param_x(PARAM_ANGULAR_FORCE_LIMIT, angular_limit_force_limit)
	#set_param_x(PARAM_ANGULAR_LOWER_LIMIT, angular_limit_lower_angle)
	#set_param_x(PARAM_ANGULAR_UPPER_LIMIT, angular_limit_upper_angle)
	#set_param_x(PARAM_ANGULAR_LIMIT_SOFTNESS, angular_limit_softness)
	#set_param_x(PARAM_ANGULAR_RESTITUTION, angular_limit_restitution)
	#set_param_x(PARAM_ANGULAR_DAMPING, angular_limit_damping)

	set_param_y(PARAM_LINEAR_LOWER_LIMIT, linear_limit_lower_distance)
	set_param_y(PARAM_LINEAR_UPPER_LIMIT, linear_limit_upper_distance)
	set_param_y(PARAM_LINEAR_RESTITUTION, linear_limit_restitution)
	set_param_y(PARAM_LINEAR_LIMIT_SOFTNESS, linear_limit_softness)
	set_param_y(PARAM_LINEAR_DAMPING, linear_limit_damping)
	set_param_y(PARAM_LINEAR_SPRING_DAMPING, linear_spring_damping)
	set_param_y(PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT, linear_spring_equilibrium_point)
	set_param_y(PARAM_LINEAR_SPRING_STIFFNESS, linear_spring_stiffness)
	#set_param_y(PARAM_ANGULAR_ERP, angular_limit_erp)
	#set_param_y(PARAM_ANGULAR_FORCE_LIMIT, angular_limit_force_limit)
	#set_param_y(PARAM_ANGULAR_LOWER_LIMIT, angular_limit_lower_angle)
	#set_param_y(PARAM_ANGULAR_UPPER_LIMIT, angular_limit_upper_angle)
	#set_param_y(PARAM_ANGULAR_LIMIT_SOFTNESS, angular_limit_softness)
	#set_param_y(PARAM_ANGULAR_RESTITUTION, angular_limit_restitution)
	#set_param_y(PARAM_ANGULAR_DAMPING, angular_limit_damping)

	set_param_z(PARAM_LINEAR_LOWER_LIMIT, linear_limit_lower_distance)
	set_param_z(PARAM_LINEAR_UPPER_LIMIT, linear_limit_upper_distance)
	set_param_z(PARAM_LINEAR_RESTITUTION, linear_limit_restitution)
	set_param_z(PARAM_LINEAR_LIMIT_SOFTNESS, linear_limit_softness)
	set_param_z(PARAM_LINEAR_DAMPING, linear_limit_damping)
	set_param_z(PARAM_LINEAR_SPRING_DAMPING, linear_spring_damping)
	set_param_z(PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT, linear_spring_equilibrium_point)
	set_param_z(PARAM_LINEAR_SPRING_STIFFNESS, linear_spring_stiffness)
	#set_param_z(PARAM_ANGULAR_ERP, angular_limit_erp)
	#set_param_z(PARAM_ANGULAR_FORCE_LIMIT, angular_limit_force_limit)
	#set_param_z(PARAM_ANGULAR_LOWER_LIMIT, angular_limit_lower_angle)
	#set_param_z(PARAM_ANGULAR_UPPER_LIMIT, angular_limit_upper_angle)
	#set_param_z(PARAM_ANGULAR_LIMIT_SOFTNESS, angular_limit_softness)
	#set_param_z(PARAM_ANGULAR_RESTITUTION, angular_limit_restitution)
	#set_param_z(PARAM_ANGULAR_DAMPING, angular_limit_damping)

func _physics_process(_delta: float) -> void:
	_update_position()
	_update_params()
