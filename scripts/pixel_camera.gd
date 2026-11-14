
extends Camera2D

@export var target: Node2D


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		return

	# Follow player using whole pixel coordinates.
	global_position = target.global_position.round()
