extends Node3D

@export var build_root: NodePath

func _ready() -> void:
	await get_tree().process_frame
	var root := get_node_or_null(build_root)
	var con := Contraption.get_connector_for(root)
	for child in get_children():
		if child == root:
			continue
		if not child is RigidBody3D:
			continue
		if not child.is_in_group("build"):
			continue
		con.attach_bodies(root, child)
