extends Area3D

var _spawn_locations: Dictionary = {}

func _on_body_entered(node: Node3D):
	_spawn_locations[node.get_path()] = node.global_position

func _on_body_exited(node: Node3D):
	var path := node.get_path()
	if _spawn_locations.has(path):
		node.global_position = _spawn_locations[path]
		if node is CharacterBody3D:
			node.velocity *= 0
		elif node is RigidBody3D:
			node.linear_velocity *= 0
			node.angular_velocity *= 0
		_spawn_locations.erase(path)

	if node is RigidBody3D:
		var con := ConnectionGroup.get_connector_for(node)
		if con:
			con.detach_body(node)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
