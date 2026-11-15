
extends CharacterBody2D
class_name Enemy


@export_group("Enemy Sounds")

@export var shoot_sfx: AudioStream
@export var hit_sfx: AudioStream
@export var death_sfx: AudioStream


# --- ENEMY SETTINGS ---

@export var max_health: int = 2

@export var move_speed: float = 45.0
@export var retreat_distance: float = 65.0
@export var dodge_distance: float = 85.0

@export var detection_range: float = 320.0
@export var fire_interval: float = 1.6

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 90.0

@export var triple_shot: bool = false
@export var spread_angle_degrees: float = 45.0


# --- NODE REFERENCES ---

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_timer: Timer = $ShootTimer


# --- VARIABLES ---

var health: int
var player: Node2D

var facing_direction: Vector2 = Vector2.DOWN

var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

var showing_attack_animation: bool = false
var is_hurt: bool = false
var is_dead: bool = false


func _ready() -> void:
	add_to_group("enemies")

	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	health = max_health

	player = get_tree().get_first_node_in_group("player") as Node2D

	print("Enemy ready!")
	print("Player found: ", is_instance_valid(player))
	print("Projectile assigned: ", projectile_scene != null)

	if not is_instance_valid(player):
		push_warning("Player missing from group 'player'")

	shoot_timer.wait_time = fire_interval
	shoot_timer.one_shot = false

	shoot_timer.timeout.connect(shoot)
	sprite.animation_finished.connect(_on_animation_finished)

	shoot_timer.start()
	play_movement_animation()


# --- ENEMY AI ---

func _physics_process(delta: float) -> void:
	if is_dead or is_hurt:
		velocity = Vector2.ZERO
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

		if not is_instance_valid(player):
			velocity = Vector2.ZERO
			return

	var to_player: Vector2 = player.global_position - global_position

	if to_player.length_squared() > 1.0:
		facing_direction = to_player.normalized()

	var move_direction: Vector2 = choose_movement(to_player, delta)

	velocity = move_direction * move_speed
	move_and_slide()

	if not showing_attack_animation:
		play_movement_animation()


# --- MOVEMENT DECISIONS ---

func choose_movement(to_player: Vector2, delta: float) -> Vector2:

	# Priority 1: Dodge reflected projectiles
	var dodge_direction: Vector2 = get_dodge_direction()

	if dodge_direction != Vector2.ZERO:
		return dodge_direction

	# Priority 2: Run away if player is too close
	if to_player.length() < retreat_distance:
		if to_player.length_squared() > 1.0:
			return -to_player.normalized()

	# Stop if player is too far away
	if to_player.length() > detection_range:
		return Vector2.ZERO

	# Priority 3: Occasionally wander
	wander_timer -= delta

	if wander_timer <= 0.0:
		wander_timer = randf_range(0.6, 1.4)

		# Sometimes stay still
		if randf() < 0.55:
			wander_direction = Vector2.ZERO
		else:
			var angle: float = randf_range(0.0, TAU)
			wander_direction = Vector2.RIGHT.rotated(angle)

	return wander_direction


# --- PROJECTILE DODGING ---

func get_dodge_direction() -> Vector2:
	for node in get_tree().get_nodes_in_group("projectiles"):
		var projectile := node as Projectile

		if projectile == null:
			continue

		# Ignore normal enemy projectiles
		if not projectile.is_reflected:
			continue

		var to_enemy: Vector2 = global_position - projectile.global_position

		# Check whether the projectile is travelling toward us
		var forward_distance: float = to_enemy.dot(projectile.direction)

		if forward_distance < 0.0 or forward_distance > dodge_distance:
			continue

		# Check whether its path passes close to us
		var sideways_distance: float = abs(
			to_enemy.cross(projectile.direction)
		)

		if sideways_distance > 18.0:
			continue

		# Step sideways out of the projectile's path
		var side: Vector2 = Vector2(
			-projectile.direction.y,
			projectile.direction.x
		)

		if side.dot(to_enemy) < 0.0:
			side = -side

		return side

	return Vector2.ZERO


# --- SHOOTING ---


func shoot() -> void:
	if is_dead or is_hurt:
		return

	if not is_instance_valid(player):
		return

	if projectile_scene == null:
		push_warning("Enemy has no projectile scene assigned!")
		return

	var to_player: Vector2 = player.global_position - global_position

	if to_player.length() > detection_range:
		return

	if to_player.length_squared() < 1.0:
		return

	# Aim at the player's current position
	facing_direction = to_player.normalized()

	if triple_shot:
		# Left spread, center, right spread
		spawn_projectile(-spread_angle_degrees)
		spawn_projectile(0.0)
		spawn_projectile(spread_angle_degrees)
	else:
		# Original enemy: just one projectile
		spawn_projectile(0.0)

	play_attack_animation()
	AudioManager.play_sfx(shoot_sfx, -6.0)


func spawn_projectile(angle_degrees: float) -> void:
	var projectile := projectile_scene.instantiate() as Projectile

	if projectile == null:
		push_warning("Projectile scene needs projectile.gd!")
		return

	# Rotate the firing direction
	var shot_direction: Vector2 = facing_direction.rotated(
		deg_to_rad(angle_degrees)
	).normalized()

	# Set projectile properties before adding to scene
	projectile.starting_direction = shot_direction
	projectile.speed = projectile_speed

	get_tree().current_scene.add_child(projectile)

	# All three projectiles emerge from the same firing point
	projectile.global_position = (
		global_position + facing_direction * 24.0
	)



# --- HEALTH ---

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	print("Enemy health: ", health)

	if health <= 0:
		die()
	else:
		play_hit_animation()


func play_hit_animation() -> void:
	AudioManager.play_sfx(hit_sfx)
	is_hurt = true
	showing_attack_animation = false

	velocity = Vector2.ZERO

	var animation_name := find_animation("hit")

	if animation_name == "":
		is_hurt = false
		push_warning("Missing enemy hit animation!")
		return

	sprite.play(animation_name)


func die() -> void:
	AudioManager.play_sfx(death_sfx)
	is_dead = true
	is_hurt = false
	showing_attack_animation = false

	velocity = Vector2.ZERO

	# Stop shooting permanently
	shoot_timer.stop()

	# Stop the enemy blocking other objects
	collision_layer = 0
	collision_mask = 0
	$CollisionShape2D.set_deferred("disabled", true)

	var animation_name := find_animation("death")

	if animation_name == "":
		queue_free()
		return

	sprite.play(animation_name)



# --- ANIMATIONS ---

func get_direction_name() -> String:
	if abs(facing_direction.x) > abs(facing_direction.y):
		if facing_direction.x > 0:
			return "right"
		return "left"

	if facing_direction.y > 0:
		return "down"

	return "up"


func find_animation(action: String) -> String:
	var name: String = action + "_" + get_direction_name()

	if sprite.sprite_frames.has_animation(name):
		return name

	if sprite.sprite_frames.has_animation(action):
		return action

	return ""


func play_movement_animation() -> void:
	var action: String = "idle"

	if velocity.length_squared() > 1.0:
		action = "walk"

	var name: String = find_animation(action)

	if name == "":
		name = find_animation("idle")

	if name == "":
		name = find_animation("walk")

	if name == "":
		return

	if sprite.animation != name or not sprite.is_playing():
		sprite.play(name)


func play_attack_animation() -> void:
	if is_dead or is_hurt:
		return
	var name: String = find_animation("attack")

	if name == "":
		name = find_animation("shoot")

	if name == "":
		return

	showing_attack_animation = true
	sprite.play(name)


func _on_animation_finished() -> void:
	if is_dead:
		queue_free()
		return

	if is_hurt:
		is_hurt = false
		play_movement_animation()
		return

	if showing_attack_animation:
		showing_attack_animation = false
		play_movement_animation()
