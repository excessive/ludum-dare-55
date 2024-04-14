extends StaticBody3D

@onready var _trigger := %trigger
@onready var _switch := %switch

signal changed(pressed: bool)
signal pressed
signal released

func _ready() -> void:
	_trigger.body_entered.connect(_on_press)
	_trigger.body_exited.connect(_on_release)

func _on_press(node: Node3D):
	if node != _switch:
		return
	changed.emit(true)
	pressed.emit()
	print("press!")
	
func _on_release(node: Node3D):
	if node != _switch:
		return
	changed.emit(false)
	released.emit()
	print("release!")
