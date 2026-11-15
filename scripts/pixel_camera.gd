
extends Camera2D

@export var target: Node2D


func _ready() -> void:
	# Follow after player movement; Godot interpolates the camera between ticks.
	process_physics_priority = 100
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = false
	_update_position()


func _physics_process(_delta: float) -> void:
	_update_position()


func _update_position() -> void:
	if not is_instance_valid(target):
		return

	global_position = target.global_position
	force_update_scroll()
