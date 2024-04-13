extends CharacterBody3D

@export var camera: FollowCam
@export var grabber: Area3D
@export_range(-1.0, 1.0) var turn_speed := 0.333
@export_range(0.0, 1.0) var mouse_sensitivity := 0.125

@onready var focus := SnailInput.get_input_focus(self)
@onready var _prev_mode := Input.mouse_mode

var _allow_drag_rotate := true
var _dragging := false
var _cam_inner := Basis()
var _cam_outer := Basis()

var _grabbed_path: NodePath
var _grabbed_last_basis := Basis()
var _grabbed_last_dist := 0.0

func _ready() -> void:
	assert(camera)
	assert(grabber)
	camera.add_exclusion(self)
	camera.zoom = 0
	Input.mouse_mode = _prev_mode

func _input(event: InputEvent) -> void:
	var input := focus.get_player_input()
	if not input.has_keyboard():
		return

	if _allow_drag_rotate and event is InputEventMouseButton and event.button_index == 1:
		var was_dragging = _dragging
		if event.is_pressed() or event.is_released():
			_dragging = event.is_pressed()
		if _dragging != was_dragging:
			if _dragging:
				_prev_mode = Input.mouse_mode
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = _prev_mode

	# make sure to block bg captured mouse input
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or not get_viewport().get_window().has_focus():
		return

	if event is InputEventMouseMotion:
		var sens := turn_speed * TAU * mouse_sensitivity
		target_rotate(event.relative * sens)

func target_rotate(r: Vector2):
	var pitch := deg_to_rad(-r.y)
	var yaw := deg_to_rad(-r.x)

	var rx = _cam_inner.get_euler() + Vector3(pitch, 0, 0)
	rx.x = clampf(rx.x, PI / -2 + 0.01, PI / 2 - 0.01)
	_cam_inner = Basis.from_euler(rx)

	var ry := _cam_outer.get_euler() + Vector3(0, yaw, 0)
	_cam_outer = Basis.from_euler(ry)

func _get_gravity() -> Vector3:
	return PhysicsServer3D.body_get_direct_state(get_rid()).total_gravity

func _get_nearest_item(p_group: StringName) -> RigidBody3D:
	var viewport_size := camera.get_viewport().get_visible_rect().size
	var nearest_body: RigidBody3D = null
	var nearest_dist: float = 1000.0
	for body in grabber.get_overlapping_bodies():
		if not body.is_in_group(p_group):
			continue
		if not body is RigidBody3D:
			continue
		if not camera.is_position_in_frustum(body.global_position):
			continue
		var dist := global_position.distance_to(body.global_position)
		var uv := camera.unproject_position(body.global_position) / viewport_size
		dist *= uv.distance_to(Vector2(0.5, 0.5)) # bias toward screen center
		if dist < nearest_dist or not nearest_body:
			nearest_body = body
			nearest_dist = dist
	return nearest_body

func _try_grab() -> bool:
	var item := _get_nearest_item("build")
	if not item:
		return false

	item.linear_velocity *= 0
	item.angular_velocity *= 0
	item.gravity_scale = 0

	var center := get_viewport().get_visible_rect().get_center()
	var depth := camera.global_position.distance_to(global_position)
	var origin := camera.project_position(center, depth)
	_grabbed_last_basis = camera.global_basis
	_grabbed_last_dist = origin.distance_to(item.global_position)
	_grabbed_path = item.get_path()
	return true

func _try_move(delta: float):
	var grabbed: RigidBody3D = get_node_or_null(_grabbed_path)
	if not grabbed or not _grabbed_last_basis:
		return

	var center := get_viewport().get_visible_rect().get_center()
	var depth := camera.global_position.distance_to(global_position)
	var origin := camera.project_position(center, depth)
	var old_pos := (grabbed as Node3D).global_position
	var new_pos := origin + camera.project_ray_normal(center) * _grabbed_last_dist
	var smooth_pos := old_pos.lerp(new_pos, 1.0 - exp(-5 * delta))
	grabbed.angular_velocity *= exp(-5 * delta)
	grabbed.linear_velocity = (smooth_pos - old_pos) / delta + velocity + get_platform_velocity()

func _physics_process(_delta: float) -> void:
	var input := focus.get_player_input()

	var move := input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var speed := 25.0 * _delta

	var move_basis := camera.global_basis
	var flat_forward := (move_basis.z * (Vector3.ONE - up_direction)).normalized()
	var flat_right := move_basis.y.cross(flat_forward).normalized()

	if is_on_floor():
		velocity *= exp(-5.0 * _delta)
		if input.is_action_just_pressed("jump"):
			velocity += -_get_gravity() * 0.5
	else:
		velocity *= exp(-0.5 * _delta)
		speed /= 4.0

	velocity += flat_forward * move.y * speed
	velocity += flat_right * move.x * speed
	velocity += _get_gravity() * _delta

	move_and_slide()

	var view := Input.get_vector("view_left", "view_right", "view_up", "view_down").limit_length()
	var sens := rad_to_deg(turn_speed * TAU * _delta)
	target_rotate(view * sens)

	camera.target_transform = Transform3D(_cam_outer * _cam_inner, global_position)

	_try_move(_delta)

	if input.is_action_just_pressed("grab"):
		if _grabbed_path:
			(get_node_or_null(_grabbed_path) as RigidBody3D).gravity_scale = 1
			_grabbed_path = ""
		elif _try_grab():
			print(_grabbed_path)
