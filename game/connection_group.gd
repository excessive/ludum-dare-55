class_name ConnectionGroup
extends Node3D

var _connections: Dictionary = {}
var _constraints: Array[Joint3D] = []

static func get_connector_for(item: RigidBody3D) -> ConnectionGroup:
	while true:
		if not item.is_inside_tree():
			break
		var parent := item.get_parent()
		if not parent:
			break
		elif parent is ConnectionGroup:
			return parent
	return null

func _is_connected(a: RigidBody3D, b: RigidBody3D) -> bool:
	var path_a := a.get_path()
	var path_b := b.get_path()
	if not _connections.has(path_a):
		_connections[path_a] = []
	if not _connections.has(path_b):
		_connections[path_b] = []
	if _connections[path_a].has(path_b) or _connections[path_b].has(path_a):
		return true
	return false

func attach_bodies(a: RigidBody3D, b: RigidBody3D):
	var path_a := a.get_path()
	var path_b := b.get_path()
	if not _is_connected(a, b):
		var constraint := GlueJoint.new(a, b)
		_connections[path_a].append(path_b)
		_connections[path_b].append(path_a)
		a.add_sibling(constraint)
		_constraints.append(constraint)
		#print("attached %s and %s" % [a.name, b.name])

func detach_body(body: RigidBody3D):
	var path := body.get_path()
	if not _connections.has(path):
		return
	var connections := _connections[path] as Array
	var erase: Array[Joint3D] = []
	for connection: NodePath in connections:
		if not _connections.has(connection):
			continue
		_connections[connection].erase(path)
		for constraint in _constraints:
			if constraint.node_a == path or constraint.node_b == path:
				erase.append(constraint)
				_connections[constraint.node_a].erase(constraint.node_b)
				_connections[constraint.node_b].erase(constraint.node_a)
	for joint in erase:
		_constraints.erase(joint)
		joint.queue_free()
