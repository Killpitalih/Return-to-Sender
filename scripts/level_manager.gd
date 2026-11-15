extends Node2D

var transitioning: bool = false
var current_room: Node2D
var fade: ColorRect


func _ready() -> void:
	AudioManager.play_music(preload("res://audio/music/background.mp3"))
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_room = $Room01
	_connect_room()
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fade)
	# Gameplay pauses during fades while this controller keeps running.
	for child in get_children():
		if child != overlay:
			child.process_mode = Node.PROCESS_MODE_PAUSABLE
	if get_tree().has_meta("fade_into_game"):
		get_tree().remove_meta("fade_into_game")
		transitioning = true
		fade.color.a = 1.0
		get_tree().paused = true
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_interval(0.08)
		tween.tween_property(fade, "color:a", 0.0, 0.55)
		await tween.finished
		get_tree().paused = false
		transitioning = false


func _connect_room() -> void:
	if current_room.has_signal("exit_entered"):
		current_room.connect("exit_entered", _change_room)
	if current_room.has_signal("game_completed"):
		current_room.connect("game_completed", _finish_game)


func _finish_game() -> void:
	if transitioning:
		return
	transitioning = true
	$Player.velocity = Vector2.ZERO
	$Player._stop_footsteps()
	get_tree().paused = true
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().paused = false
	var error := get_tree().change_scene_to_file("res://scenes/ui/ending.tscn")
	if error != OK:
		push_error("Unable to show ending: " + error_string(error))
		tween = create_tween()
		tween.tween_property(fade, "color:a", 0.0, 0.3)
		await tween.finished
		transitioning = false


func _change_room(path: String) -> void:
	if transitioning or path.is_empty():
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Cannot load room: " + path)
		return
	transitioning = true
	$Player.velocity = Vector2.ZERO
	$Player._stop_footsteps()
	get_tree().paused = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.22)
	await tween.finished
	remove_child(current_room)
	current_room.queue_free()
	current_room = packed.instantiate()
	current_room.process_mode = Node.PROCESS_MODE_PAUSABLE
	var spawn := current_room.get_node_or_null("PlayerSpawn") as Node2D
	$Player.position = spawn.position if spawn != null else Vector2(160, 90)
	$Player.reset_physics_interpolation()
	add_child(current_room)
	_connect_room()
	$Camera2D.global_position = $Player.global_position
	$Camera2D.reset_physics_interpolation()
	$Camera2D.force_update_scroll()
	tween = create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.22)
	await tween.finished
	get_tree().paused = false
	transitioning = false
