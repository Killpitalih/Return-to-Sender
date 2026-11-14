
extends CharacterBody2D

@export var move_speed: float = 90.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bounce_attack: BounceAttack = $BounceAttack

var facing_direction: Vector2 = Vector2.DOWN


func _physics_process(_delta: float) -> void:
	# Read movement input
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	# Player movement
	velocity = direction * move_speed
	move_and_slide()

	# Remember last movement direction
	if direction != Vector2.ZERO:
		facing_direction = choose_facing_direction(direction)
		#facing_direction = direction

	# Attack toward mouse cursor
	if Input.is_action_just_pressed("bounce"):
		bounce_attack.start_attack(get_global_mouse_position())

	# Update player animations
	update_animation(direction)


func update_animation(direction: Vector2) -> void:
	var animation_name: String = ""

	if bounce_attack.is_attacking:
		# Attacking while moving
		if direction != Vector2.ZERO:
			animation_name = get_animation_name(
				"walk_attack",
				bounce_attack.aim_direction
			)

		# Standing attack or fallback
		if animation_name == "":
			animation_name = get_animation_name(
				"attack",
				bounce_attack.aim_direction
			)

	elif direction != Vector2.ZERO:
		# Normal walking
		animation_name = get_animation_name(
			"walk",
			facing_direction
		)

	else:
		# Normal idle
		animation_name = get_animation_name(
			"idle",
			facing_direction
		)

	if animation_name == "":
		return

	# Don't restart an attack every frame
	if sprite.animation != animation_name:
		sprite.play(animation_name)
	elif not sprite.is_playing() and not bounce_attack.is_attacking:
		sprite.play()


func get_animation_name(
	action: String,
	direction: Vector2
) -> String:
	var direction_name: String

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			direction_name = "right"
		else:
			direction_name = "left"
	else:
		if direction.y > 0:
			direction_name = "down"
		else:
			direction_name = "up"

	# Example: attack_right, walk_down, idle_up
	var name: String = action + "_" + direction_name

	if sprite.sprite_frames.has_animation(name):
		return name

	# Fallback for animations named just "attack"
	if sprite.sprite_frames.has_animation(action):
		return action

	return ""
	

func choose_facing_direction(direction: Vector2) -> Vector2:
	var horizontal: Vector2

	if direction.x > 0:
		horizontal = Vector2.RIGHT
	else:
		horizontal = Vector2.LEFT

	var vertical: Vector2

	if direction.y > 0:
		vertical = Vector2.DOWN
	else:
		vertical = Vector2.UP

	# Only moving vertically
	if is_zero_approx(direction.x):
		return vertical

	# Only moving horizontally
	if is_zero_approx(direction.y):
		return horizontal

	# Moving diagonally:
	# Keep facing the previous direction if possible
	if facing_direction == horizontal:
		return horizontal

	if facing_direction == vertical:
		return vertical

	# Default to vertical if changing from
	# an unrelated direction
	return vertical
