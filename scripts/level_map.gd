extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	_add_background()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_right", 70)
	margin.add_theme_constant_override("margin_top", 45)
	margin.add_theme_constant_override("margin_bottom", 45)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Карта обучения"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	root.add_child(title)

	var info := Label.new()
	info.text = "Выберите уровень. В первой сборке доступны все темы для проверки переходов между сценами."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 18)
	root.add_child(info)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	root.add_child(grid)

	for lesson in TaskLoader.get_lessons():
		if typeof(lesson) != TYPE_DICTIONARY:
			continue

		var level := int(lesson.get("level", 1))
		var title_text := str(lesson.get("title", "Уровень"))
		var button := Button.new()
		button.text = _get_level_button_text(level, title_text)
		button.custom_minimum_size = Vector2(520, 86)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_on_level_pressed.bind(level))
		grid.add_child(button)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(bottom_spacer)

	var back_button := Button.new()
	back_button.text = "Назад в главное меню"
	back_button.custom_minimum_size = Vector2(300, 48)
	back_button.add_theme_font_size_override("font_size", 18)
	back_button.pressed.connect(_on_back_pressed)
	root.add_child(back_button)

func _add_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.08, 0.12)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

func _get_level_button_text(level: int, title_text: String) -> String:
	var status := "Не пройден"
	if AppState.is_level_completed(level):
		status = "Пройден"
	return "Уровень %d: %s\nСтатус: %s" % [level, title_text, status]

func _on_level_pressed(level: int) -> void:
	AppState.selected_level = level
	get_tree().change_scene_to_file("res://scenes/LessonScene.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
