extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	_add_background()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Результат уровня"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	root.add_child(title)

	var status := Label.new()
	if AppState.last_answer_correct:
		status.text = "Уровень %d пройден" % AppState.selected_level
	else:
		status.text = "Уровень %d пока не пройден" % AppState.selected_level
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 28)
	root.add_child(status)

	var stats := Label.new()
	stats.text = "Очки: %d\nОшибки: %d\nПройденные уровни: %s" % [
		AppState.score,
		AppState.mistakes,
		str(AppState.completed_levels)
	]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 22)
	root.add_child(stats)

	var explanation := Label.new()
	explanation.text = AppState.last_explanation
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 20)
	explanation.custom_minimum_size = Vector2(800, 120)
	root.add_child(explanation)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	root.add_child(buttons)

	var map_button := Button.new()
	map_button.text = "Карта уровней"
	map_button.custom_minimum_size = Vector2(220, 50)
	map_button.add_theme_font_size_override("font_size", 18)
	map_button.pressed.connect(_on_map_pressed)
	buttons.add_child(map_button)

	var retry_button := Button.new()
	retry_button.text = "Повторить уровень"
	retry_button.custom_minimum_size = Vector2(240, 50)
	retry_button.add_theme_font_size_override("font_size", 18)
	retry_button.pressed.connect(_on_retry_pressed)
	buttons.add_child(retry_button)

	var next_button := Button.new()
	next_button.text = "Следующий уровень"
	next_button.custom_minimum_size = Vector2(250, 50)
	next_button.add_theme_font_size_override("font_size", 18)
	next_button.disabled = not AppState.last_answer_correct or AppState.selected_level >= TaskLoader.get_max_level()
	next_button.pressed.connect(_on_next_pressed)
	buttons.add_child(next_button)

	var menu_button := Button.new()
	menu_button.text = "Главное меню"
	menu_button.custom_minimum_size = Vector2(220, 50)
	menu_button.add_theme_font_size_override("font_size", 18)
	menu_button.pressed.connect(_on_menu_pressed)
	root.add_child(menu_button)

func _add_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.08, 0.12)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TaskScene.tscn")

func _on_next_pressed() -> void:
	AppState.selected_level += 1
	AppState.last_answer_correct = false
	AppState.last_explanation = ""
	get_tree().change_scene_to_file("res://scenes/LessonScene.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
