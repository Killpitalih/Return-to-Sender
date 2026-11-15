extends Control

var leaving: bool = false
var fade: ColorRect


func _ready() -> void:
	$Center/Menu/Play.pressed.connect(_main_menu)
	$Center/Menu/Exit.pressed.connect(_exit)
	$Center/Menu/Play.disabled = true
	$Center/Menu/Exit.disabled = true
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fade)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.1)
	tween.tween_property(fade, "color:a", 0.0, 0.55)
	await tween.finished
	$Center/Menu/Play.disabled = false
	$Center/Menu/Exit.disabled = false
	$Center/Menu/Play.grab_focus()


func _main_menu() -> void:
	if leaving:
		return
	leaving = true
	$Center/Menu/Play.disabled = true
	$Center/Menu/Exit.disabled = true
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	await tween.finished
	var error := get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	if error != OK:
		push_error("Unable to open main menu: " + error_string(error))
		fade.color.a = 0.0
		leaving = false
		$Center/Menu/Play.disabled = false
		$Center/Menu/Exit.disabled = false


func _exit() -> void:
	get_tree().quit()
