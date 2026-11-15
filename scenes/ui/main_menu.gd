extends Control

var starting: bool = false
var fade: ColorRect


func _ready() -> void:
	$Center/Menu/Play.pressed.connect(_play)
	$Center/Menu/Exit.pressed.connect(_exit)
	$Center/Menu/HowToPlay.pressed.connect(_show_instructions)
	$Instructions/Center/Panel/Margin/Content/Close.pressed.connect(_close_instructions)
	$DifficultyCenter/Choices/Back.pressed.connect(_back)
	$DifficultyCenter/Choices/Insane.pressed.connect(_start_game.bind(1))
	$DifficultyCenter/Choices/Hard.pressed.connect(_start_game.bind(3))
	$DifficultyCenter/Choices/Medium.pressed.connect(_start_game.bind(5))
	$DifficultyCenter/Choices/Easy.pressed.connect(_start_game.bind(10))
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
	$Center.hide()
	$DifficultyCenter.show()
	$DifficultyCenter/Choices/Medium.grab_focus()


func _show_instructions() -> void:
	$Instructions.show()
	$Center/Menu/Play.focus_mode = Control.FOCUS_NONE
	$Center/Menu/HowToPlay.focus_mode = Control.FOCUS_NONE
	$Center/Menu/Exit.focus_mode = Control.FOCUS_NONE
	$Instructions/Center/Panel/Margin/Content/Close.grab_focus()


func _close_instructions() -> void:
	$Instructions.hide()
	$Center/Menu/Play.focus_mode = Control.FOCUS_ALL
	$Center/Menu/HowToPlay.focus_mode = Control.FOCUS_ALL
	$Center/Menu/Exit.focus_mode = Control.FOCUS_ALL
	$Center/Menu/HowToPlay.grab_focus()


func _back() -> void:
	if starting:
		return
	$DifficultyCenter.hide()
	$Center.show()
	$Center/Menu/Play.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not starting:
		if $Instructions.visible:
			_close_instructions()
		elif $DifficultyCenter.visible:
			_back()
		get_viewport().set_input_as_handled()


func _set_buttons_disabled(disabled: bool) -> void:
	for container in [$Center/Menu, $DifficultyCenter/Choices]:
		for child in container.get_children():
			if child is Button:
				child.disabled = disabled


func _start_game(health: int) -> void:
	if starting:
		return
	starting = true
	get_tree().set_meta("player_max_health", health)
	_set_buttons_disabled(true)
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
		_set_buttons_disabled(false)
		$DifficultyCenter/Choices/Medium.grab_focus()
		push_error("Unable to start game: " + error_string(error))


func _exit() -> void:
	get_tree().quit()
