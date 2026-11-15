extends Node2D

signal arena_entered(player: Node2D)
signal game_completed

@export var boss: Enemy
@export var boss_music: AudioStream = preload("res://audio/music/boss_fight.mp3")

@onready var arena_entrance: RoomDoor = $Arena/EntranceDoor
@onready var arena_trigger: Area2D = $Arena/EntryTrigger

var arena_started: bool = false


func _ready() -> void:
	arena_trigger.body_entered.connect(_on_arena_entered)
	if is_instance_valid(boss):
		boss.died.connect(_on_boss_died, CONNECT_ONE_SHOT)


func _on_boss_died() -> void:
	# Let the boss's death animation finish before leaving the level.
	await boss.tree_exited
	if not is_queued_for_deletion():
		game_completed.emit()


func _on_arena_entered(body: Node2D) -> void:
	if arena_started or not body.is_in_group("player"):
		return
	arena_started = true
	arena_entrance.close_door()
	AudioManager.play_music(boss_music)
	arena_entered.emit(body)


# Call from your fight controller when the encounter is finished.
func open_arena() -> void:
	arena_entrance.open_door()
