extends RigidBody3D

signal use(user: Node3D)
signal reset

@export var torque := 500
@export var speed := 175
@export var active := 0.0

@onready var wheel := %spinny
@onready var motor := %motor

func _ready() -> void:
	use.connect(_on_use)
	reset.connect(_on_reset)

func _on_reset():
	active = 0.0
	wheel.angular_velocity *= 0
	wheel.linear_velocity *= 0

func _on_use(_user: Node3D):
	active = 10.0

func _physics_process(delta: float) -> void:
	if active <= 0.0:
		motor.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
		return
	active -= delta
	#var force := -global_basis.x * torque * delta
	#wheel.apply_torque(force)
	motor.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	motor.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, deg_to_rad(speed))
	motor.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, torque)
