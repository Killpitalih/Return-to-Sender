
extends Node
class_name PlayerHealth

signal health_changed(current_health: int, maximum_health: int)
signal damaged
signal died

@export var max_health: int = 3
@export var invincibility_seconds: float = 1.0

var current_health: int
var is_dead: bool = false

@onready var invulnerability_timer: Timer = $InvulnerabilityTimer


func _ready() -> void:
	max_health = int(get_tree().get_meta("player_max_health", max_health))
	#max_health = 1000 # debug
	current_health = max_health

	invulnerability_timer.one_shot = true
	invulnerability_timer.stop()


func take_damage(amount: int) -> void:
	# Ignore damage during invincibility
	if is_dead or not invulnerability_timer.is_stopped():
		return

	if amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)

	print("Player HP: ", current_health, "/", max_health)

	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		is_dead = true
		died.emit()
	else:
		invulnerability_timer.start(invincibility_seconds)
		damaged.emit()


func is_invulnerable() -> bool:
	return is_dead or not invulnerability_timer.is_stopped()
