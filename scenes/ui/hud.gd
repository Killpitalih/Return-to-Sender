
extends CanvasLayer

@export var full_heart: Texture2D
@export var empty_heart: Texture2D

@onready var hearts: HBoxContainer = $Hearts


func _ready() -> void:
	# Find the player already registered in our project
	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		push_warning("HUD: Player not found!")
		return

	var health := player.get_node_or_null("HealthComponent") as PlayerHealth

	if health == null:
		push_warning("HUD: HealthComponent not found!")
		return

	# Update HUD whenever the player loses or gains HP
	health.health_changed.connect(update_hearts)

	# Draw the starting HP
	update_hearts(health.current_health, health.max_health)


func update_hearts(current: int, maximum: int) -> void:
	# Remove previous heart icons
	for child in hearts.get_children():
		hearts.remove_child(child)
		child.queue_free()

	# Create one heart for every maximum HP
	for i in range(maximum):
		var heart := TextureRect.new()

		heart.texture = full_heart if i < current else empty_heart

		# Use a faded full heart if no empty-heart art exists
		if i >= current and empty_heart == null:
			heart.texture = full_heart
			heart.modulate.a = 0.25

		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.custom_minimum_size = Vector2(16, 16)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE

		hearts.add_child(heart)
