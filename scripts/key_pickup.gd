
extends Area2D
class_name KeyPickup

signal picked_up

@export var pickup_sfx: AudioStream

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	else:
		sprite.play()


func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	if not body.is_in_group("player"):
		return

	collected = true
	
	AudioManager.play_sfx(pickup_sfx)

	picked_up.emit()
	queue_free()
