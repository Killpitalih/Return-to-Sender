
extends Node2D
class_name RoomDoor

@export var open_sfx: AudioStream
@export var close_sfx: AudioStream

var state_initialized: bool = false

@export var starts_closed: bool = true

@onready var open_tiles: TileMapLayer = $OpenTiles
@onready var closed_tiles: TileMapLayer = $ClosedTiles
@onready var blocker: CollisionShape2D = $Blocker/CollisionShape2D

var is_closed: bool = false


func _ready() -> void:
	# Door physics are handled by our separate blocker.
	open_tiles.collision_enabled = false
	closed_tiles.collision_enabled = false

	open_tiles.visible = true
	closed_tiles.visible = true

	set_closed(starts_closed)
	state_initialized = true


func set_closed(value: bool) -> void:
	if state_initialized and is_closed == value:
		return
	is_closed = value

	open_tiles.enabled = not value
	closed_tiles.enabled = value

	blocker.set_deferred("disabled", not value)
	if state_initialized:
		if value:
			AudioManager.play_sfx(close_sfx)
		else:
			AudioManager.play_sfx(open_sfx)


func open_door() -> void:
	set_closed(false)


func close_door() -> void:
	set_closed(true)
