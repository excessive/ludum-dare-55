extends VehicleBody3D

signal control(user: Node3D, input: Vector3)
signal use(user: Node3D)
signal reset

@export var torque := 50
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
	var tick := get_physics_process_delta_time()
	active = tick
	var weight := 1.0 - exp(-3.0 * tick)
	engine_force = lerpf(engine_force, torque * input.y, weight)
	steering = lerpf(steering, deg_to_rad(30) * -input.x, weight)

func _physics_process(delta: float) -> void:
	if active <= 0.0:
		engine_force = 0
		return
	#print(engine_force, " ", steering)
	active -= delta
