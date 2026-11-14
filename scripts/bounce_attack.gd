
extends Area2D
class_name BounceAttack

signal attack_started
signal attack_finished

# How long the attack can reflect projectiles
@export var active_time: float = 0.6

# How long to wait after the attack ends
@export var cooldown_time: float = 0.45

# How far the attack reaches in front of the player
@export var attack_reach: float = 13.0

var is_attacking: bool = false
var aim_direction: Vector2 = Vector2.DOWN

@onready var hitbox: CollisionShape2D = $CollisionShape2D
@onready var active_timer: Timer = $ActiveTimer
@onready var cooldown_timer: Timer = $CooldownTimer


func _ready() -> void:
	# The hitbox is inactive until we attack
	monitoring = false
	hitbox.disabled = true

	active_timer.one_shot = true
	cooldown_timer.one_shot = true

	active_timer.timeout.connect(finish_attack)
	area_entered.connect(_on_area_entered)


func start_attack(target_position: Vector2) -> void:
	# Don't attack while another attack or cooldown is active
	if is_attacking or not cooldown_timer.is_stopped():
		return

	# Find direction from player to mouse cursor
	var player: Node2D = get_parent() as Node2D
	var direction: Vector2 = target_position - player.global_position

	if direction.length_squared() > 1.0:
		aim_direction = direction.normalized()

	# Place the hitbox in front of the player
	position = aim_direction * attack_reach
	rotation = aim_direction.angle()

	# Activate attack
	is_attacking = true
	monitoring = true
	hitbox.set_deferred("disabled", false)

	active_timer.start(active_time)
	cooldown_timer.start(active_time + cooldown_time)

	queue_redraw()
	attack_started.emit()


func finish_attack() -> void:
	is_attacking = false
	monitoring = false
	hitbox.set_deferred("disabled", true)

	#queue_redraw()
	attack_finished.emit()
	

func _on_area_entered(area: Area2D) -> void:
	if not is_attacking:
		return

	if area is Projectile:
		if not area.is_reflected:
			area.bounce_toward(get_global_mouse_position())
