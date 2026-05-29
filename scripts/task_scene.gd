extends Control

var task: Dictionary = {}
var answer_buttons: Array[Button] = []
var result_label: Label
var next_button: Button

func _ready() -> void:
	task = TaskLoader.get_first_task_for_level(AppState.selected_level)
	_build_ui()

func _build_ui() -> void:
	_add_background()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_top", 55)
	margin.add_theme_constant_override("margin_bottom", 55)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Задание уровня %d" % AppState.selected_level
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	root.add_child(title)

	var question_panel := PanelContainer.new()
	root.add_child(question_panel)

	var question_margin := MarginContainer.new()
	question_margin.add_theme_constant_override("margin_left", 22)
	question_margin.add_theme_constant_override("margin_right", 22)
	question_margin.add_theme_constant_override("margin_top", 22)
	question_margin.add_theme_constant_override("margin_bottom", 22)
	question_panel.add_child(question_margin)

	var question := Label.new()
	question.text = str(task.get("question", ""))
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.add_theme_font_size_override("font_size", 24)
	question_margin.add_child(question)

	var answers_box := VBoxContainer.new()
	answers_box.add_theme_constant_override("separation", 12)
	root.add_child(answers_box)

	var answers: Array = task.get("answers", [])
	for index in range(answers.size()):
		var button := Button.new()
		button.text = str(answers[index])
		button.custom_minimum_size = Vector2(0, 54)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_on_answer_selected.bind(index))
		answer_buttons.append(button)
		answers_box.add_child(button)

	result_label = Label.new()
	result_label.text = "Выберите один из вариантов ответа."
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 20)
	root.add_child(result_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	root.add_child(buttons)

	var back_button := Button.new()
	back_button.text = "Назад к уроку"
	back_button.custom_minimum_size = Vector2(230, 50)
	back_button.add_theme_font_size_override("font_size", 18)
	back_button.pressed.connect(_on_back_pressed)
	buttons.add_child(back_button)

	var retry_button := Button.new()
	retry_button.text = "Повторить"
	retry_button.custom_minimum_size = Vector2(200, 50)
	retry_button.add_theme_font_size_override("font_size", 18)
	retry_button.pressed.connect(_on_retry_pressed)
	buttons.add_child(retry_button)

	next_button = Button.new()
	next_button.text = "К результату"
	next_button.custom_minimum_size = Vector2(220, 50)
	next_button.add_theme_font_size_override("font_size", 18)
	next_button.disabled = true
	next_button.pressed.connect(_on_next_pressed)
	buttons.add_child(next_button)

func _add_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.08, 0.12)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

func _on_answer_selected(index: int) -> void:
	var correct_index := int(task.get("correct", -1))
	var is_correct := index == correct_index
	var explanation := str(task.get("explanation", ""))

	AppState.last_answer_correct = is_correct
	AppState.last_explanation = explanation

	if is_correct:
		AppState.add_score(10)
		AppState.complete_level(AppState.selected_level)
		result_label.text = "Верно! +10 очков.\n\n" + explanation
	else:
		AppState.add_mistake()
		result_label.text = "Неверно. Попробуйте разобрать объяснение.\n\n" + explanation

	for button in answer_buttons:
		button.disabled = true

	next_button.disabled = false

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LessonScene.tscn")

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_next_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ResultScene.tscn")
