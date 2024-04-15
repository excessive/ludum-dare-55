extends Node3D
class_name Autobuild

@export var build_root: NodePath

func _ready() -> void:
	await get_tree().process_frame
	var root := get_node_or_null(build_root)
	assert(root)
	for child in get_children():
		if child == root:
			continue
		if not child is RigidBody3D:
			continue
		if not child.is_in_group("build"):
			continue
		Contraption.attach_bodies(root, [child])

	#print(Contraption.get_all_bodies(root))
