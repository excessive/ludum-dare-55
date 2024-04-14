class_name Contraption
extends Node3D

var _connections: Dictionary = {}
var _constraints: Array[Joint3D] = []

static func get_connector_for(item: RigidBody3D) -> Contraption:
	if not item.is_inside_tree():
		return null
	var node: Node = item.get_parent()
	while node:
		if node is Contraption:
			return node
		node = node.get_parent()
	return node
	#print("new contraption")
	#var ret := Contraption.new()
	#item.add_sibling(ret)
	#ret.global_position = item.global_position
	#item.reparent(ret)
	#return ret

static func get_joints_for(item: RigidBody3D) -> Array[Joint3D]:
	var connector := get_connector_for(item)
	var ret: Array[Joint3D] = []
	if connector:
		var path := item.get_path()
		for constraint: Joint3D in connector._constraints:
			if constraint.node_a == path or constraint.node_b == path:
				ret.append(constraint)
	return ret

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
		#a.reparent(self)
		#b.reparent(self)
		var constraint := GlueJoint.new(a, b)
		constraint.linear_spring_equilibrium_point = a.global_position.distance_to(b.global_position)
		_connections[path_a].append(path_b)
		_connections[path_b].append(path_a)
		add_child(constraint)
		_constraints.append(constraint)
		#print("attached %s and %s" % [a.name, b.name])

func detach_body(body: RigidBody3D):
	var path := body.get_path()
	if not _connections.has(path):
		return
	#body.reparent(get_parent())
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
