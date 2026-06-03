extends Control

const PYTHON_CONSOLE_SCENE: PackedScene = preload("res://scenes/components/PythonConsole.tscn")

@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var mission_briefing_label: Label = %MissionBriefingLabel
@onready var objectives_label: Label = %ObjectivesLabel
@onready var example_console: PythonConsole = %ExampleConsole as PythonConsole
@onready var back_button: Button = %BackButton
@onready var task_button: Button = %TaskButton
@onready var content_box: VBoxContainer = $RootMargin/RootLayout/ContentScroll/ContentBox

var lesson: Dictionary = {}
var interaction: Dictionary = {}
var interactive_panel: PanelContainer
var lab_status_label: Label
var lab_log_label: Label
var selected_code_label: Label
var assembled_code_view: TextEdit
var token_list: VBoxContainer
var scan_button: Button
var clear_assembly_button: Button
var check_assembly_button: Button
var access_button: Button
var lab_console: PythonConsole
var selected_token_indexes: Array[int] = []
var selected_token_lines: Array[String] = []
var token_buttons: Array[Button] = []

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	task_button.pressed.connect(_on_task_pressed)
	_show_lesson()

func _show_lesson() -> void:
	lesson = ContentRepository.get_lesson(AppState.selected_level)
	interaction = LessonInteractionService.get_interaction(AppState.selected_level)
	title_label.text = "%s" % MissionService.get_mission_title(AppState.selected_level)
	body_label.text = _build_lesson_text(lesson)
	mission_briefing_label.text = MissionService.get_mission_briefing(AppState.selected_level)
	objectives_label.text = _build_objectives_text(lesson)

	_build_interactive_lab()
	example_console.setup_example(lesson)
	_update_task_button_state()

func _build_lesson_text(lesson_data: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Тема сектора: %s" % str(lesson_data.get("title", "Тема")))
	lines.append("")
	lines.append(str(lesson_data.get("text", "")))
	lines.append("")
	lines.append("Перед основной практикой уровень теперь проходит через игровой тренажер. Игрок сначала активирует сектор, собирает рабочий фрагмент кода и запускает его в терминале. После этого открывается доступ к узлам миссии.")
	return "\n".join(lines)

func _build_objectives_text(lesson_data: Dictionary) -> String:
	var objectives: Array = _variant_to_array(lesson_data.get("objectives", []))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Что нужно освоить для прохождения миссии:")
	if objectives.is_empty():
		lines.append("- решить игровые узлы уровня и применить тему на практике")
	else:
		for item in objectives:
			lines.append("- " + str(item))
	lines.append("- пройти интерактивный тренажер сектора: сканирование, сборка кода, запуск терминала и допуск")
	lines.append("- сохранить энергию системы и не повышать тревогу лишними ошибками")
	return "\n".join(lines)

func _build_interactive_lab() -> void:
	if interactive_panel != null:
		interactive_panel.queue_free()

	selected_token_indexes.clear()
	selected_token_lines.clear()
	token_buttons.clear()

	interactive_panel = PanelContainer.new()
	interactive_panel.name = "InteractiveLessonLab"
	interactive_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_child(interactive_panel)
	content_box.move_child(interactive_panel, 3)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	interactive_panel.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var title: Label = _make_label("Интерактивный тренажер сектора", 24, true)
	root.add_child(title)

	var purpose: Label = _make_wrapped_label(str(interaction.get("purpose", "Перед практикой активируй учебный контур уровня.")), 18)
	root.add_child(purpose)

	lab_status_label = _make_wrapped_label("", 17)
	root.add_child(lab_status_label)

	root.add_child(_build_scan_block())
	root.add_child(_build_assembly_block())
	root.add_child(_build_console_block())
	root.add_child(_build_access_block())

	lab_log_label = _make_wrapped_label("Журнал: сначала просканируй сектор.", 17)
	root.add_child(lab_log_label)

	_refresh_lab_state()

func _build_scan_block() -> PanelContainer:
	var panel: PanelContainer = _make_inner_panel()
	var box: VBoxContainer = _get_panel_box(panel)
	box.add_child(_make_label("1. Сканер сектора", 20, true))
	box.add_child(_make_wrapped_label(str(interaction.get("scan_text", "Сканер ожидает запуска.")), 17))
	scan_button = Button.new()
	scan_button.text = "Сканировать сектор"
	scan_button.custom_minimum_size = Vector2(260, 44)
	scan_button.pressed.connect(_on_scan_pressed)
	box.add_child(scan_button)
	return panel

func _build_assembly_block() -> PanelContainer:
	var panel: PanelContainer = _make_inner_panel()
	var box: VBoxContainer = _get_panel_box(panel)
	box.add_child(_make_label("2. Ремонт фрагмента кода", 20, true))
	box.add_child(_make_wrapped_label(str(interaction.get("assembly_goal", "Собери фрагмент кода.")), 17))

	selected_code_label = _make_wrapped_label("Рабочий модуль пока пустой.", 16)
	box.add_child(selected_code_label)

	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(columns)

	var token_panel: PanelContainer = _make_inner_panel()
	token_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(token_panel)
	var token_box: VBoxContainer = _get_panel_box(token_panel)
	token_box.add_child(_make_label("Доступные строки", 17, true))
	token_list = VBoxContainer.new()
	token_list.add_theme_constant_override("separation", 8)
	token_box.add_child(token_list)
	_build_token_buttons()

	var module_panel: PanelContainer = _make_inner_panel()
	module_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(module_panel)
	var module_box: VBoxContainer = _get_panel_box(module_panel)
	module_box.add_child(_make_label("Собранный модуль", 17, true))
	assembled_code_view = TextEdit.new()
	assembled_code_view.custom_minimum_size = Vector2(0, 190)
	assembled_code_view.editable = false
	assembled_code_view.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	assembled_code_view.add_theme_font_size_override("font_size", 17)
	module_box.add_child(assembled_code_view)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	module_box.add_child(buttons)

	clear_assembly_button = Button.new()
	clear_assembly_button.text = "Сбросить"
	clear_assembly_button.custom_minimum_size = Vector2(150, 42)
	clear_assembly_button.pressed.connect(_on_clear_assembly_pressed)
	buttons.add_child(clear_assembly_button)

	check_assembly_button = Button.new()
	check_assembly_button.text = "Проверить сборку"
	check_assembly_button.custom_minimum_size = Vector2(220, 42)
	check_assembly_button.pressed.connect(_on_check_assembly_pressed)
	buttons.add_child(check_assembly_button)

	return panel

func _build_console_block() -> PanelContainer:
	var panel: PanelContainer = _make_inner_panel()
	var box: VBoxContainer = _get_panel_box(panel)
	box.add_child(_make_label("3. Запуск учебного терминала", 20, true))
	box.add_child(_make_wrapped_label(str(interaction.get("console_goal", "Запусти код и проверь результат.")), 17))

	lab_console = PYTHON_CONSOLE_SCENE.instantiate() as PythonConsole
	box.add_child(lab_console)
	var lab_task: Dictionary = {
		"console_title": str(interaction.get("console_title", "Учебный терминал")),
		"starter_code": "",
		"placeholder": "Сначала собери фрагмент кода выше.",
		"initial_output": "Секторный терминал ожидает рабочий модуль."
	}
	lab_console.setup(lab_task)
	lab_console.run_requested.connect(_on_lab_console_run_requested)
	return panel

func _build_access_block() -> PanelContainer:
	var panel: PanelContainer = _make_inner_panel()
	var box: VBoxContainer = _get_panel_box(panel)
	box.add_child(_make_label("4. Допуск к миссии", 20, true))
	box.add_child(_make_wrapped_label(str(interaction.get("unlock_text", "После тренажера откроется миссия.")), 17))
	access_button = Button.new()
	access_button.text = "Получить допуск к практическим узлам"
	access_button.custom_minimum_size = Vector2(360, 44)
	access_button.pressed.connect(_on_access_pressed)
	box.add_child(access_button)
	return panel

func _build_token_buttons() -> void:
	for child in token_list.get_children():
		child.queue_free()

	var tokens: Array = LessonInteractionService.get_tokens(AppState.selected_level)
	for index in range(tokens.size()):
		var button: Button = Button.new()
		button.text = str(tokens[index])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 40)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_on_token_pressed.bind(index, str(tokens[index])))
		token_buttons.append(button)
		token_list.add_child(button)

func _on_scan_pressed() -> void:
	AppState.complete_lesson_step(AppState.selected_level, "scan")
	SaveManager.save_game()
	lab_log_label.text = "Журнал: сектор просканирован. Теперь собери поврежденный фрагмент кода."
	AudioManager.play_success()
	_refresh_lab_state()

func _on_token_pressed(index: int, line: String) -> void:
	if not AppState.is_lesson_step_completed(AppState.selected_level, "scan"):
		lab_log_label.text = "Журнал: сначала запусти сканер. Без диагностики стенд не принимает строки кода."
		AudioManager.play_error()
		return
	if AppState.is_lesson_step_completed(AppState.selected_level, "assemble"):
		return
	selected_token_indexes.append(index)
	selected_token_lines.append(line)
	if index >= 0 and index < token_buttons.size():
		token_buttons[index].disabled = true
	_update_assembled_code_view()

func _on_clear_assembly_pressed() -> void:
	if AppState.is_lesson_step_completed(AppState.selected_level, "assemble"):
		return
	selected_token_indexes.clear()
	selected_token_lines.clear()
	for button in token_buttons:
		button.disabled = false
	_update_assembled_code_view()
	lab_log_label.text = "Журнал: рабочий модуль очищен. Собери строки заново."

func _on_check_assembly_pressed() -> void:
	if not AppState.is_lesson_step_completed(AppState.selected_level, "scan"):
		lab_log_label.text = "Журнал: сборка недоступна до сканирования сектора."
		AudioManager.play_error()
		return
	var result: Dictionary = LessonInteractionService.evaluate_assembly(AppState.selected_level, selected_token_indexes)
	lab_log_label.text = "Журнал: %s\n%s" % [str(result.get("message", "")), str(result.get("details", ""))]
	if bool(result.get("is_correct", false)):
		AppState.complete_lesson_step(AppState.selected_level, "assemble")
		lab_console.set_code(LessonInteractionService.get_correct_code(AppState.selected_level))
		lab_console.set_output("Код загружен. Нажми Run для запуска секторного модуля.")
		SaveManager.save_game()
		AudioManager.play_success()
	else:
		AudioManager.play_error()
	_refresh_lab_state()

func _on_lab_console_run_requested(source_code: String) -> void:
	if not AppState.is_lesson_step_completed(AppState.selected_level, "assemble"):
		lab_console.set_output("Сначала собери фрагмент кода на стенде ремонта.")
		lab_log_label.text = "Журнал: терминал заблокирован до правильной сборки модуля."
		AudioManager.play_error()
		return
	var result: Dictionary = LessonInteractionService.evaluate_console(AppState.selected_level, source_code)
	lab_console.set_output(str(result.get("console_output", "")))
	lab_log_label.text = "Журнал: %s\n%s" % [str(result.get("message", "")), str(result.get("details", ""))]
	if bool(result.get("is_correct", false)):
		AppState.complete_lesson_step(AppState.selected_level, "console")
		SaveManager.save_game()
		AudioManager.play_success()
	else:
		AudioManager.play_error()
	_refresh_lab_state()

func _on_access_pressed() -> void:
	if not AppState.is_lesson_step_completed(AppState.selected_level, "scan"):
		lab_log_label.text = "Журнал: допуск закрыт. Сначала просканируй сектор."
		AudioManager.play_error()
		return
	if not AppState.is_lesson_step_completed(AppState.selected_level, "assemble"):
		lab_log_label.text = "Журнал: допуск закрыт. Сначала собери фрагмент кода."
		AudioManager.play_error()
		return
	if not AppState.is_lesson_step_completed(AppState.selected_level, "console"):
		lab_log_label.text = "Журнал: допуск закрыт. Сначала запусти код в терминале."
		AudioManager.play_error()
		return
	AppState.complete_lesson_step(AppState.selected_level, "access")
	SaveManager.save_game()
	lab_log_label.text = "Журнал: допуск получен. Можно переходить к практическим узлам миссии."
	AudioManager.play_success()
	_refresh_lab_state()
	_update_task_button_state()

func _refresh_lab_state() -> void:
	lab_status_label.text = LessonInteractionService.build_access_text(AppState.selected_level)

	var scan_done: bool = AppState.is_lesson_step_completed(AppState.selected_level, "scan")
	var assemble_done: bool = AppState.is_lesson_step_completed(AppState.selected_level, "assemble")
	var console_done: bool = AppState.is_lesson_step_completed(AppState.selected_level, "console")
	var access_done: bool = AppState.is_lesson_step_completed(AppState.selected_level, "access")

	if scan_button != null:
		scan_button.disabled = scan_done
		scan_button.text = "Сектор просканирован" if scan_done else "Сканировать сектор"
	if clear_assembly_button != null:
		clear_assembly_button.disabled = not scan_done or assemble_done
	if check_assembly_button != null:
		check_assembly_button.disabled = not scan_done or assemble_done
	if assemble_done and assembled_code_view != null and assembled_code_view.text.strip_edges().is_empty():
		assembled_code_view.text = LessonInteractionService.get_correct_code(AppState.selected_level)
		selected_code_label.text = "Фрагмент собран ранее."
	if lab_console != null:
		lab_console.set_locked(not assemble_done or console_done)
		if assemble_done and lab_console.is_code_empty():
			lab_console.set_code(LessonInteractionService.get_correct_code(AppState.selected_level))
	if access_button != null:
		access_button.disabled = access_done
		access_button.text = "Допуск открыт" if access_done else "Получить допуск к практическим узлам"
	for index in range(token_buttons.size()):
		var button: Button = token_buttons[index]
		button.disabled = not scan_done or assemble_done or selected_token_indexes.has(index)
	_update_task_button_state()

func _update_assembled_code_view() -> void:
	var lines: PackedStringArray = PackedStringArray()
	for line in selected_token_lines:
		lines.append(line)
	var code_text: String = "\n".join(lines)
	assembled_code_view.text = code_text
	selected_code_label.text = "Выбрано строк: %d" % [selected_token_lines.size()]

func _update_task_button_state() -> void:
	var task_count: int = ContentRepository.get_task_count_for_level(AppState.selected_level)
	var completed_count: int = ContentRepository.get_completed_task_count_for_level(AppState.selected_level)
	var first_incomplete_index: int = ContentRepository.get_first_incomplete_task_index_for_level(AppState.selected_level)
	var lab_completed: bool = LessonInteractionService.is_lesson_lab_completed(AppState.selected_level)
	var already_started_level: bool = completed_count > 0

	if not lab_completed and not already_started_level:
		task_button.disabled = true
		task_button.text = "Сначала пройди тренажер сектора"
		return

	task_button.disabled = false
	if completed_count >= task_count and task_count > 0:
		task_button.text = "Повторить миссию (%d/%d узлов)" % [completed_count, task_count]
	else:
		task_button.text = "Продолжить миссию: узел %d/%d" % [first_incomplete_index + 1, task_count]

func _make_inner_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	return panel

func _get_panel_box(panel: PanelContainer) -> VBoxContainer:
	var margin: MarginContainer = panel.get_child(0) as MarginContainer
	return margin.get_child(0) as VBoxContainer

func _make_label(text_value: String, font_size: int, centered: bool = false) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _make_wrapped_label(text_value: String, font_size: int) -> Label:
	var label: Label = _make_label(text_value, font_size, false)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _variant_to_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result: Array = []
	for item in value:
		result.append(item)
	return result

func _on_back_pressed() -> void:
	SceneRouter.go_to_level_map()

func _on_task_pressed() -> void:
	var task_index: int = ContentRepository.get_first_incomplete_task_index_for_level(AppState.selected_level)
	AppState.select_task_index(task_index)
	SceneRouter.go_to_task()
