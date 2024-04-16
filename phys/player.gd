extends CharacterBody3D

@export var pause_menu: PackedScene
@export var camera: FollowCam
@export var grabber: Area3D
@export_range(-1.0, 1.0) var turn_speed := 0.333
@export_range(0.0, 1.0) var mouse_sensitivity := 0.125

@onready var focus := SnailInput.get_input_focus(self)
@onready var _prev_mode := Input.MOUSE_MODE_CAPTURED
@onready var respawn_transform := global_transform
#@onready var _prev_mode := Input.mouse_mode

var _allow_drag_rotate := false
var _dragging := false
var _cam_inner := Basis()
var _cam_outer := Basis()

var _grabbed_path: NodePath
var _grabbed_last_basis := Basis()
var _grabbed_last_dist := 0.0
var _grabbed_continuous_cd := false

var _controlling_path: NodePath
var _control_locator: Node3D

@onready var _last_position = global_position

signal reset

func _ready() -> void:
	assert(camera)
	assert(grabber)
	camera.add_exclusion(self)
	Input.mouse_mode = _prev_mode
	reset.connect(_on_reset)

func _on_reset():
	drop_item()
	drop_control()
	velocity *= 0
	global_transform = respawn_transform
	_last_position = respawn_transform.origin

func drop_item():
	var item: RigidBody3D = get_node_or_null(_grabbed_path)
	if item:
		item.linear_damp = 0
		item.gravity_scale = 1
		item.continuous_cd = _grabbed_continuous_cd
		item.remove_collision_exception_with(self)
		_grabbed_path = ""

func _input(event: InputEvent) -> void:
	var input := focus.get_player_input()

	if input.is_action_pressed("pause") and event.is_pressed():
		_prev_mode = Input.mouse_mode
		var menu := pause_menu.instantiate()
		menu.restart_scene = get_parent().scene_file_path
		print_debug(menu.restart_scene)
		add_child(menu)
		await get_tree().process_frame
		get_tree().paused = true
		await menu.tree_exited
		Input.mouse_mode = _prev_mode
		return

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
		var controlling := get_node_or_null(_controlling_path)
		if input.is_action_pressed("rotate") and not controlling:
			_try_rotate_item(event.relative * sens, 0.01)
		else:
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

func _try_attach(item: RigidBody3D):
	if not item:
		return
	if Contraption.attach_bodies(item, _find_attachments(item)):
		drop_item()

func drop_control():
	_controlling_path = ""
	if _control_locator:
		_control_locator.queue_free()
		_control_locator = null

func _try_control(controlling: RigidBody3D, delta: float) -> bool:
	if not controlling:
		return false

	var input := focus.get_player_input()
	var vehicle_control := Vector3(
		input.get_axis("move_left", "move_right"),
		Input.get_axis("reverse", "throttle"),
		0
	)
	if not Contraption.control(controlling, self, vehicle_control):
		drop_control()
		return false


	var view := input.get_vector("view_left", "view_right", "view_up", "view_down").limit_length()
	var sens := rad_to_deg(turn_speed * TAU * delta)
	target_rotate(view * sens)

	camera.target_transform = Transform3D(_closest_alignment(global_basis, controlling.global_basis) * _cam_outer * _cam_inner, global_position)

	return true

## returns try to cancel remaining update
func _try_use(delta: float) -> bool:
	var held := get_node_or_null(_grabbed_path)
	if held:
		if not Contraption.has_any_attachments(held):
			_try_attach(held)
		else:
			Contraption.detach_body(held)
		return false

	var controlling: RigidBody3D = get_node_or_null(_controlling_path)
	if controlling:
		drop_control()
		return true # eat this input so we don't use on leave
	else:
		controlling = _get_nearest_item("build")
		if _try_control(controlling, delta):
			velocity *= 0
			global_position += global_basis.y * 0.5 # hack, move up a bit
			var remote = RemoteTransform3D.new()
			remote.remote_path = get_path()
			remote.name = "player_remote"
			_control_locator = Node3D.new()
			controlling.add_child(_control_locator)
			_control_locator.global_transform = global_transform
			_control_locator.add_child(remote)
			remote.position *= 0
			_controlling_path = controlling.get_path()
			return true

	var item := _get_nearest_item("usable")
	if not item:
		print("item not found")
		return false

	# use on a frozen item unfreezes it instead
	if item.freeze:
		Contraption.freeze(item, true)
		return false

	Contraption.activate(item, self)

	return false

func _try_freeze() -> bool:
	var held: RigidBody3D = get_node_or_null(_grabbed_path)
	var item := _get_nearest_item("build")
	if item:
		Contraption.freeze(item)
		if item == held:
			drop_item()
		return true
	return false

func _try_grab() -> bool:
	var item := _get_nearest_item("build")
	if not item:
		return false

	if item.is_in_group("no_grab") or item.mass >= 100:
		return false

	if item.has_signal("reset"):
		item.emit_signal("reset")

	item.linear_velocity *= 0
	item.angular_velocity *= 0
	item.gravity_scale = 0
	_grabbed_continuous_cd = item.continuous_cd
	item.continuous_cd = true
	item.add_collision_exception_with(self)

	var center := get_viewport().get_visible_rect().get_center()
	var depth := camera.global_position.distance_to(global_position)
	var origin := camera.project_position(center, depth)
	_grabbed_last_basis = camera.global_basis
	_grabbed_last_dist = origin.distance_to(item.global_position)
	_grabbed_path = item.get_path()
	item.freeze = false

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
	grabbed.linear_damp = 2

	if focus.get_player_input().is_action_pressed("rotate"):
		return

	var hits := _find_attachments(grabbed, 1.0)
	for hit in hits:
		var target_basis := _closest_alignment(grabbed.global_basis, hit.global_basis)
		var align_speed := 20.0 * delta
		#print(target_basis)
		grabbed.angular_velocity += calc_angular_velocity(grabbed.global_basis, target_basis) * align_speed
		break # just ignore everything after the first hit

func _closest_vector(b: Basis, v: Vector3) -> Vector3:
	var cmp := Vector3(b.x.dot(v), b.y.dot(v), b.z.dot(v))
	var axis := cmp.abs().max_axis_index()
	return b[axis] * signf(cmp[axis])

func _closest_alignment(from_basis: Basis, to_basis: Basis) -> Basis:
	var cx := _closest_vector(to_basis, from_basis.x)
	var cy := _closest_vector(to_basis, from_basis.y)
	return Basis(cx, cy, cx.cross(cy)).orthonormalized()

func calc_angular_velocity(from_basis: Basis, to_basis: Basis) -> Vector3:
	return (to_basis * from_basis.inverse()).get_euler()

func _try_rotate_item(view: Vector2, speed: float = 1.0):
	var item := get_node_or_null(_grabbed_path) as RigidBody3D
	if not item or not view:
		return
	var ax := camera.global_basis.x
	var ay := camera.global_basis.y
	# this can't be done in _input, so defer it
	await get_tree().physics_frame
	item.global_rotate(ax, view.y * speed)
	item.global_rotate(ay, view.x * speed)

func _has_script_vars(object: Object) -> bool:
	for prop in object.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			return true
	return false

var cycle := 0

func _find_attachments(item: RigidBody3D, margin := 0.25) -> Array[RigidBody3D]:
	var ret: Array[RigidBody3D] = []
	var dss := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	params.collide_with_areas = false
	params.collide_with_bodies = true
	for collider in item.get_children():
		if not collider is CollisionShape3D:
			continue
		params.transform = collider.global_transform
		params.shape = collider.shape
		params.exclude = [ item ]
		params.margin = margin
		var hits := dss.intersect_shape(params)
		for hit in hits:
			if hit.collider is RigidBody3D and hit.collider.is_in_group("build"):
				ret.append(hit.collider)
	ret.sort_custom(func(a, b):
		var da = a.global_position.distance_to(global_position)
		var db = b.global_position.distance_to(global_position)
		return da > db
	)
	return ret

@onready var pusher_pos: Vector3 = to_local($pusher.global_position)

func _physics_process(delta: float) -> void:
	if global_position.distance_to(_last_position) > 3:
		print("warp detected, resetting")
		reset.emit()
	_last_position = global_position

	var input := focus.get_player_input()

	camera.zoom = 3

	if input.is_action_just_pressed("use"):
		if _try_use(delta):
			return
	elif _try_control(get_node_or_null(_controlling_path), delta):
		return

	camera.zoom = 0

	$pusher.apply_central_impulse((to_global(pusher_pos) - $pusher.global_position) * 10)

	if input.is_action_just_pressed("debug") and OS.is_debug_build():
		var item := _get_nearest_item("build")
		var inspector := %ObjectInspector
		if item and inspector:
			var options: Array[Node3D] = [ item ]
			options.append_array(Contraption.get_joints_for(item))
			cycle %= options.size()
			var choice := options[cycle]
			if inspector.get_object() == choice:
				cycle += 1
				cycle %= options.size()
				choice = options[cycle]
			inspector.show()
			inspector.set_object(choice, _has_script_vars(choice))
			print("inspect %s" % choice.name)
		else:
			cycle = 0
			print("clearing inspector")
			inspector.clear()
			inspector.hide()

	var move := input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var speed := 25.0 * delta

	var move_basis := camera.global_basis
	var flat_forward := (move_basis.z * (Vector3.ONE - up_direction)).normalized()
	var flat_right := move_basis.y.cross(flat_forward).normalized()

	if is_on_floor():
		velocity *= exp(-5.0 * delta)
		if input.is_action_just_pressed("jump"):
			velocity += -_get_gravity() * 0.66667
	else:
		velocity *= exp(-0.5 * delta)
		speed /= 4.0

	velocity += flat_forward * move.y * speed
	velocity += flat_right * move.x * speed
	velocity += _get_gravity() * delta
	velocity = velocity.limit_length(50)

	move_and_slide()

	var view := input.get_vector("view_left", "view_right", "view_up", "view_down").limit_length()
	var sens := rad_to_deg(turn_speed * TAU * delta)

	_try_move(delta)

	if input.is_action_pressed("rotate"):
		_try_rotate_item(view * sens, delta)
	else:
		target_rotate(view * sens)

	# attempt to reset up
	global_basis = Basis.looking_at(-global_basis.z * Vector3(1, 0, 1))
	camera.target_transform = Transform3D(global_basis * _cam_outer * _cam_inner, global_position)

	if input.is_action_just_pressed("freeze"):
		_try_freeze()

	if input.is_action_just_pressed("grab"):
		var item := get_node_or_null(_grabbed_path) as RigidBody3D
		if item:
			#_try_attach(item)
			drop_item()
		else:
			_try_grab()
