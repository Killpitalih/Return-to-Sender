extends Control

var starting: bool = false
var fade: ColorRect


func _ready() -> void:
	$Center/Menu/Play.pressed.connect(_play)
	$Center/Menu/Exit.pressed.connect(_exit)
	$Center/Menu/Play.grab_focus()
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fade)


func _play() -> void:
	if starting:
		return
	starting = true
	$Center/Menu/Play.disabled = true
	$Center/Menu/Exit.disabled = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	await tween.finished
	get_tree().set_meta("fade_into_game", true)
	var error := get_tree().change_scene_to_file("res://scenes/levels/main.tscn")
	if error != OK:
		get_tree().remove_meta("fade_into_game")
		tween = create_tween()
		tween.tween_property(fade, "color:a", 0.0, 0.22)
		await tween.finished
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		starting = false
		$Center/Menu/Play.disabled = false
		$Center/Menu/Exit.disabled = false
		$Center/Menu/Play.grab_focus()
		push_error("Unable to start game: " + error_string(error))


func _exit() -> void:
	get_tree().quit()
