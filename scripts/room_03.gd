extends Node2D

signal arena_entered(player: Node2D)

@onready var arena_entrance: RoomDoor = $Arena/EntranceDoor
@onready var arena_trigger: Area2D = $Arena/EntryTrigger

var arena_started: bool = false


func _ready() -> void:
	arena_trigger.body_entered.connect(_on_arena_entered)


func _on_arena_entered(body: Node2D) -> void:
	if arena_started or not body.is_in_group("player"):
		return
	arena_started = true
	arena_entrance.close_door()
	arena_entered.emit(body)


# Call from your fight controller when the encounter is finished.
func open_arena() -> void:
	arena_entrance.open_door()
