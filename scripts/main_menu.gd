extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	_add_background()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var title := Label.new()
	title.text = "PyQuest"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Игровое приложение для изучения основ Python"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	root.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	root.add_child(spacer)

	var new_game_button := _make_button("Новая игра")
	new_game_button.pressed.connect(_on_new_game_pressed)
	root.add_child(new_game_button)

	var continue_button := _make_button("Продолжить")
	continue_button.pressed.connect(_on_continue_pressed)
	root.add_child(continue_button)

	var lesson_button := _make_button("Обучение")
	lesson_button.pressed.connect(_on_lesson_pressed)
	root.add_child(lesson_button)

	var exit_button := _make_button("Выход")
	exit_button.pressed.connect(_on_exit_pressed)
	root.add_child(exit_button)

func _add_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.08, 0.12)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 54)
	button.add_theme_font_size_override("font_size", 22)
	return button

func _on_new_game_pressed() -> void:
	AppState.reset_game()
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

func _on_lesson_pressed() -> void:
	AppState.selected_level = 1
	get_tree().change_scene_to_file("res://scenes/LessonScene.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
