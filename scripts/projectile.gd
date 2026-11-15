
extends Area2D
class_name Projectile

@export var speed: float = 90.0
@export var starting_direction: Vector2 = Vector2.LEFT

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction: Vector2 = Vector2.LEFT
var is_reflected: bool = false


func _ready() -> void:
	add_to_group("projectiles")
	
	direction = starting_direction.normalized()

	if direction == Vector2.ZERO:
		direction = Vector2.LEFT

	body_entered.connect(_on_body_entered)
	update_animation()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


# Called when the player successfully bounces a projectile
func bounce_toward(target_position: Vector2) -> void:
	if is_reflected:
		return

	var new_direction := target_position - global_position

	if new_direction.length_squared() < 0.001:
		return

	direction = new_direction.normalized()
	is_reflected = true

	# Reflected projectiles move faster
	speed *= 1.4

	update_animation()


# Change sprite to match movement direction
func update_animation() -> void:
	var animation_name: String

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			animation_name = "fly_right"
		else:
			animation_name = "fly_left"
	else:
		if direction.y > 0:
			animation_name = "fly_down"
		else:
			animation_name = "fly_up"

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not is_reflected:
			if body.has_method("take_damage"):
				body.take_damage(1)

			queue_free()
		return

	if body.is_in_group("enemies"):
		if is_reflected:
			if body.has_method("take_damage"):
				body.take_damage(1)
			queue_free()
		return

	# Other solid objects, such as walls
	queue_free()
