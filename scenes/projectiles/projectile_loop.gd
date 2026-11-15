
extends Projectile

# How large the loops are
@export var loop_radius: float = 18.0

# How many loops happen per second
@export var loops_per_second: float = 1.5

var loop_time: float = 0.0
var previous_offset: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	# Advance the looping motion
	loop_time += delta

	var angle: float = loop_time * TAU * loops_per_second

	# Direction perpendicular to forward movement
	var sideways := Vector2(
		-direction.y,
		direction.x
	)

	# Circular movement around the forward path
	var offset: Vector2 = (
		direction * (cos(angle) - 1.0) * loop_radius
		+ sideways * sin(angle) * loop_radius
	)

	# Move forward while tracing loops
	var forward_movement: Vector2 = direction * speed * delta
	var loop_movement: Vector2 = offset - previous_offset

	global_position += forward_movement + loop_movement

	previous_offset = offset


# Preserve the existing bounce system
func bounce_toward(target_position: Vector2) -> void:
	if is_reflected:
		return

	# Use the original projectile's reflection logic
	super.bounce_toward(target_position)

	if is_reflected:
		# Begin a fresh loop from the reflection point
		loop_time = 0.0
		previous_offset = Vector2.ZERO
