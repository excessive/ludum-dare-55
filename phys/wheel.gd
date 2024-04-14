extends VehicleBody3D

signal control(user: Node3D, input: Vector3)
signal use(user: Node3D)
signal reset

@export var torque := 40
@export var active := 0.0

@onready var wheel := %spinny

func _ready() -> void:
	use.connect(_on_use)
	reset.connect(_on_reset)
	control.connect(_on_control)

func _on_reset():
	active = 0.0
	engine_force = 0

func _on_use(_user: Node3D):
	active = 10.0
	engine_force = torque

func _on_control(_user: Node3D, input: Vector3):
	active = get_physics_process_delta_time()
	engine_force = torque * input.y
	steering = deg_to_rad(30) * -input.x

func _physics_process(delta: float) -> void:
	if active <= 0.0:
		engine_force = 0
		return
	#print(engine_force, " ", steering)
	active -= delta
