extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	_add_background()

	var lesson := TaskLoader.get_lesson(AppState.selected_level)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Урок %d. %s" % [AppState.selected_level, str(lesson.get("title", "Тема"))]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	root.add_child(title)

	var text_panel := PanelContainer.new()
	text_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(text_panel)

	var text_margin := MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 24)
	text_margin.add_theme_constant_override("margin_right", 24)
	text_margin.add_theme_constant_override("margin_top", 24)
	text_margin.add_theme_constant_override("margin_bottom", 24)
	text_panel.add_child(text_margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	text_margin.add_child(content)

	var body := Label.new()
	body.text = str(lesson.get("text", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 22)
	content.add_child(body)

	var code_title := Label.new()
	code_title.text = "Пример кода:"
	code_title.add_theme_font_size_override("font_size", 20)
	content.add_child(code_title)

	var code := TextEdit.new()
	code.text = str(lesson.get("code", ""))
	code.editable = false
	code.custom_minimum_size = Vector2(0, 170)
	code.add_theme_font_size_override("font_size", 20)
	content.add_child(code)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	root.add_child(buttons)

	var back_button := Button.new()
	back_button.text = "Назад к карте"
	back_button.custom_minimum_size = Vector2(260, 50)
	back_button.add_theme_font_size_override("font_size", 18)
	back_button.pressed.connect(_on_back_pressed)
	buttons.add_child(back_button)

	var task_button := Button.new()
	task_button.text = "Перейти к заданию"
	task_button.custom_minimum_size = Vector2(300, 50)
	task_button.add_theme_font_size_override("font_size", 18)
	task_button.pressed.connect(_on_task_pressed)
	buttons.add_child(task_button)

func _add_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.08, 0.12)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

func _on_task_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TaskScene.tscn")
