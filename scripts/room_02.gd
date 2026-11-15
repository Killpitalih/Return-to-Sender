
extends Node2D

signal exit_entered(next_room: String)
signal arena_enemies_changed(remaining: int)

@export_file("*.tscn") var next_room: String = ""

# The key that will appear after the battle
@export var key_scene: PackedScene

# References to objects inside our room
@onready var entrance_door: RoomDoor = $EntranceDoor
@onready var exit_door: RoomDoor = $ExitDoor
@onready var enemies: Node2D = $Enemies
@onready var room_trigger: Area2D = $RoomTrigger

var battle_started: bool = false
var key_spawned: bool = false
var enemies_remaining: int = 0


func _ready() -> void:
	if not next_room.is_empty():
		var exit_area := Area2D.new()
		exit_area.collision_layer = 0
		exit_area.collision_mask = 1
		var exit_shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(32, 16)
		exit_shape.shape = rectangle
		exit_shape.position = Vector2(31.5, 34)
		exit_area.add_child(exit_shape)
		exit_door.add_child(exit_area)
		exit_area.body_entered.connect(_on_exit_entered)

	# Set initial door states
	entrance_door.open_door()
	exit_door.close_door()

	# Detect player entering the room
	room_trigger.body_entered.connect(_on_room_entered)

	# Count enemies in this room
	for enemy in enemies.get_children():
		if enemy is Enemy:
			enemies_remaining += 1

			# Detect when the enemy disappears
			enemy.tree_exiting.connect(
				_on_enemy_exiting.bind(enemy)
			)

	print("Room enemies: ", enemies_remaining)


func _on_room_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if battle_started:
		return

	battle_started = true

	# Close the entrance behind the player
	entrance_door.close_door()
	arena_enemies_changed.emit(enemies_remaining)

	print("Battle started!")

	if enemies_remaining == 0:
		call_deferred(
			"_spawn_key",
			body.global_position
		)


func _on_enemy_exiting(enemy: Node2D) -> void:
	enemies_remaining -= 1
	if battle_started:
		arena_enemies_changed.emit(enemies_remaining)

	print("Enemies remaining: ", enemies_remaining)

	if enemies_remaining == 0 and battle_started:
		var drop_position: Vector2 = enemy.global_position

		call_deferred(
			"_spawn_key",
			drop_position
		)


func _spawn_key(drop_position: Vector2) -> void:
	if key_spawned:
		return

	if key_scene == null:
		push_error("Assign the Key Scene in Room01!")
		return

	var key := key_scene.instantiate() as KeyPickup

	if key == null:
		push_error("Key scene must have KeyPickup script!")
		return

	key_spawned = true

	# Add key to the room
	add_child(key)
	key.global_position = drop_position

	# Listen for player collecting key
	key.picked_up.connect(_on_key_collected)

	print("Key dropped!")


func _on_key_collected() -> void:
	exit_door.open_door()
	arena_enemies_changed.emit(-1)

	print("Key collected! Exit opened!")


func _on_exit_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not exit_door.is_closed:
		exit_entered.emit(next_room)
