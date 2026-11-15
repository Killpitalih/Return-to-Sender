
extends CharacterBody2D


@export_group("Player Sounds")

@export var attack_sfx: AudioStream
@export var hit_sfx: AudioStream
@export var death_sfx: AudioStream
@export var footstep_sfx: AudioStream

@onready var footstep_timer: Timer = $FootstepTimer
var footstep_player: AudioStreamPlayer


@export var move_speed: float = 90.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bounce_attack: BounceAttack = $BounceAttack
@onready var cooldown_bar: ProgressBar = $CooldownBar

@onready var player_health: PlayerHealth = $HealthComponent

var facing_direction: Vector2 = Vector2.DOWN

var player_hurt: bool = false
var player_dead: bool = false


func _physics_process(_delta: float) -> void:
	if player_hurt or player_dead:
		_stop_footsteps()
		velocity = Vector2.ZERO
		return
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
	
	# Play footsteps only when actually moving
	if get_real_velocity().length_squared() > 4.0:
		if footstep_timer.is_stopped():
			footstep_timer.start()
	else:
		_stop_footsteps()


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
	
	
	
func _ready() -> void:
	footstep_player = AudioStreamPlayer.new()
	footstep_player.stream = footstep_sfx
	footstep_player.bus = &"SFX"
	footstep_player.volume_db = -12.0
	add_child(footstep_player)
	footstep_timer.timeout.connect(_on_footstep_timer_timeout)
	bounce_attack.attack_started.connect(_on_attack_sound)
	
	cooldown_bar.min_value = 0.0
	cooldown_bar.max_value = 1.0
	cooldown_bar.show_percentage = false
	cooldown_bar.hide()
	
	player_health.damaged.connect(_on_player_damaged)
	player_health.died.connect(_on_player_died)
	sprite.animation_finished.connect(_on_player_animation_finished)


func _process(_delta: float) -> void:
	var progress: float = bounce_attack.get_cooldown_progress()

	if progress >= 1.0:
		cooldown_bar.hide()
	else:
		cooldown_bar.show()
		cooldown_bar.value = progress
	
	# Flash the sprite while temporarily invincible
	if player_dead:
		sprite.modulate.a = 1.0
	elif player_health.is_invulnerable():
		if int(Time.get_ticks_msec() / 100) % 2 == 0:
			sprite.modulate.a = 0.4
		else:
			sprite.modulate.a = 1.0
	else:
		sprite.modulate.a = 1.0

		
		

# --- HEALTH AND DAMAGE ---

func take_damage(amount: int) -> void:
	player_health.take_damage(amount)


func _on_player_damaged() -> void:
	AudioManager.play_sfx(hit_sfx)
	player_hurt = true

	# Stop the current bounce attack
	bounce_attack.cancel_attack()

	var animation_name := get_reaction_animation("hit")

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
	else:
		# Allow playtesting without hit sprites
		player_hurt = false


func _on_player_died() -> void:
	AudioManager.play_sfx(death_sfx)
	player_dead = true
	player_hurt = false

	bounce_attack.cancel_attack()

	var animation_name := get_reaction_animation("death")

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.modulate.a = 1.0
		sprite.play(animation_name)
	else:
		# Restart if death sprites are not ready yet
		get_tree().call_deferred("reload_current_scene")


func _on_player_animation_finished() -> void:
	if player_dead:
		# Restart only after the death animation
		get_tree().call_deferred("reload_current_scene")
		return

	if player_hurt:
		player_hurt = false


# --- DIRECTIONAL REACTION ANIMATIONS ---

func get_reaction_animation(action: String) -> String:
	var direction_name: String

	if absf(facing_direction.x) > absf(facing_direction.y):
		if facing_direction.x > 0:
			direction_name = "right"
		else:
			direction_name = "left"
	else:
		if facing_direction.y > 0:
			direction_name = "down"
		else:
			direction_name = "up"

	return action + "_" + direction_name
	
	
func _on_attack_sound() -> void:
	AudioManager.play_sfx(attack_sfx)
	
	
	

func _on_footstep_timer_timeout() -> void:
	if player_hurt or player_dead or footstep_timer.is_stopped() or velocity.is_zero_approx() or get_real_velocity().length_squared() <= 4.0:
		return

	if footstep_player.stream != null and not footstep_player.playing:
		footstep_player.pitch_scale = randf_range(0.94, 1.06)
		footstep_player.play()


func _stop_footsteps() -> void:
	footstep_timer.stop()
	footstep_player.stop()
