extends Control

const ANSWER_OPTION_SCENE: PackedScene = preload("res://scenes/components/AnswerOption.tscn")
const CODE_TOKEN_SCENE: PackedScene = preload("res://scenes/components/CodeToken.tscn")

@onready var title_label: Label = %TitleLabel
@onready var type_label: Label = %TypeLabel
@onready var mission_title_label: Label = %MissionTitleLabel
@onready var mission_brief_label: Label = %MissionBriefLabel
@onready var mission_state_label: Label = %MissionStateLabel
@onready var mission_inventory_label: Label = %MissionInventoryLabel
@onready var question_label: Label = %QuestionLabel
@onready var hint_panel: PanelContainer = %HintPanel
@onready var hint_label: Label = %HintLabel
@onready var hint_button: Button = %HintButton

@onready var choice_panel: PanelContainer = %ChoicePanel
@onready var choice_list: VBoxContainer = %ChoiceList

@onready var text_input_panel: PanelContainer = %TextInputPanel
@onready var answer_input: LineEdit = %AnswerInput
@onready var check_input_button: Button = %CheckInputButton

@onready var code_order_panel: PanelContainer = %CodeOrderPanel
@onready var code_token_list: VBoxContainer = %CodeTokenList
@onready var assembled_code: TextEdit = %AssembledCode
@onready var clear_code_button: Button = %ClearCodeButton
@onready var check_code_button: Button = %CheckCodeButton

@onready var code_input_panel: PythonConsole = %CodeInputPanel as PythonConsole

@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var back_button: Button = %BackButton
@onready var retry_button: Button = %RetryButton
@onready var result_button: Button = %ResultButton

var task: Dictionary = {}
var answered: bool = false
var hint_used: bool = false
var selected_code_indexes: Array[int] = []
var selected_code_lines: Array[String] = []
var task_count: int = 1

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	result_button.pressed.connect(_on_result_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	check_input_button.pressed.connect(_on_check_input_pressed)
	answer_input.text_submitted.connect(_on_answer_input_submitted)
	clear_code_button.pressed.connect(_on_clear_code_pressed)
	check_code_button.pressed.connect(_on_check_code_pressed)
	code_input_panel.run_requested.connect(_on_code_input_run_requested)
	_load_task()

func _load_task() -> void:
	task_count = maxi(1, ContentRepository.get_task_count_for_level(AppState.selected_level))
	AppState.selected_task_index = clampi(AppState.selected_task_index, 0, task_count - 1)
	task = ContentRepository.get_task_for_level(AppState.selected_level, AppState.selected_task_index)
	answered = false
	hint_used = false
	selected_code_indexes.clear()
	selected_code_lines.clear()
	result_panel.visible = false
	hint_panel.visible = false
	retry_button.disabled = false
	result_button.disabled = true
	result_button.text = "К результату"

	title_label.text = "%s · узел %d/%d" % [MissionService.get_sector_name(AppState.selected_level), AppState.selected_task_index + 1, task_count]
	question_label.text = _build_terminal_question_text()
	type_label.text = _build_type_label_text(str(task.get("type", "single_choice")))
	_setup_mission_panel()
	_setup_hint()
	_show_task_panel(str(task.get("type", "single_choice")))

func _setup_mission_panel() -> void:
	mission_title_label.text = MissionService.get_event_title(AppState.selected_level, AppState.selected_task_index)
	mission_brief_label.text = MissionService.get_event_brief(AppState.selected_level, AppState.selected_task_index, task)
	mission_state_label.text = MissionService.get_event_status(AppState.selected_level, AppState.selected_task_index, task_count)
	mission_inventory_label.text = MissionService.get_inventory_text()

func _build_terminal_question_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Командный терминал Python запрашивает действие:")
	lines.append("")
	lines.append(str(task.get("question", "")))
	return "\n".join(lines)

func _build_type_label_text(task_type: String) -> String:
	var role: String = str(task.get("gameplay_role", "terminal"))
	var role_title: String = "Терминал"
	match role:
		"diagnostic":
			role_title = "Диагностика"
		"gateway":
			role_title = "Открытие шлюза"
		"repair":
			role_title = "Ремонт модуля"
		"routing":
			role_title = "Маршрутизация"
		"core":
			role_title = "Стабилизация ядра"
		_:
			role_title = "Терминал"
	return "%s · %s" % [role_title, TaskEvaluator.get_task_type_title(task_type)]

func _setup_hint() -> void:
	var hint_text: String = str(task.get("hint", ""))
	hint_label.text = "Подсказка терминала: " + hint_text + "\n\nШтраф: за выполнение узла с подсказкой начисляется меньше очков и слабее восстанавливается энергия."
	hint_panel.visible = false
	hint_button.disabled = hint_text.strip_edges().is_empty()
	hint_button.text = "Подсказка"

func _on_hint_pressed() -> void:
	if hint_button.disabled:
		return
	hint_used = true
	hint_panel.visible = not hint_panel.visible
	hint_button.text = "Скрыть" if hint_panel.visible else "Подсказка"

func _show_task_panel(task_type: String) -> void:
	choice_panel.visible = false
	text_input_panel.visible = false
	code_order_panel.visible = false
	code_input_panel.visible = false
	code_input_panel.set_locked(false)

	match task_type:
		"single_choice", "find_error":
			choice_panel.visible = true
			_build_answer_options(_variant_to_array(task.get("answers", [])))
		"text_input", "fill_blank":
			text_input_panel.visible = true
			_setup_text_input()
		"code_order":
			code_order_panel.visible = true
			_build_code_tokens(_variant_to_array(task.get("tokens", [])))
		"code_input":
			code_input_panel.visible = true
			_setup_code_input()
		_:
			choice_panel.visible = true
			_build_answer_options(_variant_to_array(task.get("answers", [])))

func _build_answer_options(answers: Array) -> void:
	for child in choice_list.get_children():
		child.queue_free()

	for index in range(answers.size()):
		var option: AnswerOption = ANSWER_OPTION_SCENE.instantiate() as AnswerOption
		choice_list.add_child(option)
		option.setup(index, str(answers[index]))
		option.selected.connect(_on_answer_selected)

func _setup_text_input() -> void:
	answer_input.text = ""
	answer_input.placeholder_text = str(task.get("placeholder", "Введите ответ"))
	answer_input.editable = true
	check_input_button.disabled = false
	answer_input.grab_focus()

func _build_code_tokens(tokens: Array) -> void:
	for child in code_token_list.get_children():
		child.queue_free()

	assembled_code.text = ""
	assembled_code.editable = false
	clear_code_button.disabled = false
	check_code_button.disabled = false

	for index in range(tokens.size()):
		var token: CodeToken = CODE_TOKEN_SCENE.instantiate() as CodeToken
		code_token_list.add_child(token)
		token.setup(index, str(tokens[index]))
		token.token_selected.connect(_on_code_token_selected)

func _setup_code_input() -> void:
	code_input_panel.setup(task)
	code_input_panel.set_locked(false)

func _on_answer_selected(index: int) -> void:
	if answered:
		return
	var evaluation: Dictionary = TaskEvaluator.evaluate(task, index)
	_apply_evaluation(evaluation)

func _on_check_input_pressed() -> void:
	if answered:
		return
	var evaluation: Dictionary = TaskEvaluator.evaluate(task, answer_input.text)
	_apply_evaluation(evaluation)

func _on_answer_input_submitted(_value: String) -> void:
	_on_check_input_pressed()

func _on_code_token_selected(index: int, token_text: String) -> void:
	if answered:
		return

	selected_code_indexes.append(index)
	selected_code_lines.append(token_text)
	_update_assembled_code()

	for child in code_token_list.get_children():
		var token: CodeToken = child as CodeToken
		if token != null and token.token_index == index:
			token.set_locked(true)

func _update_assembled_code() -> void:
	var lines: PackedStringArray = PackedStringArray()
	for line in selected_code_lines:
		lines.append(line)
	assembled_code.text = "\n".join(lines)

func _on_clear_code_pressed() -> void:
	if answered:
		return

	selected_code_indexes.clear()
	selected_code_lines.clear()
	_update_assembled_code()

	for child in code_token_list.get_children():
		var token: CodeToken = child as CodeToken
		if token != null:
			token.set_locked(false)

func _on_check_code_pressed() -> void:
	if answered:
		return
	var evaluation: Dictionary = TaskEvaluator.evaluate(task, selected_code_indexes)
	_apply_evaluation(evaluation)

func _on_code_input_run_requested(source_code: String) -> void:
	if answered:
		return

	var evaluation: Dictionary = TaskEvaluator.evaluate(task, source_code)
	code_input_panel.set_output(str(evaluation.get("console_output", "")))
	_apply_evaluation(evaluation)

func _apply_evaluation(evaluation: Dictionary) -> void:
	answered = true
	var is_correct: bool = bool(evaluation.get("is_correct", false))
	var points: int = int(evaluation.get("score", 0))
	var explanation: String = str(evaluation.get("explanation", ""))
	var message: String = str(evaluation.get("message", ""))
	var awarded_score: int = 0
	var task_id: int = int(task.get("id", -1))
	var is_final_task: bool = AppState.selected_task_index >= task_count - 1
	var level_completed_now: bool = false
	var event_title: String = MissionService.get_event_title(AppState.selected_level, AppState.selected_task_index)
	var mission_title: String = MissionService.get_mission_title(AppState.selected_level)
	var mission_outcome_text: String = MissionService.build_outcome_text(AppState.selected_level, AppState.selected_task_index, is_correct, task)
	var artifact: String = str(task.get("mission_artifact", ""))
	var mission_result: Dictionary = AppState.register_mission_attempt(
		AppState.selected_level,
		task_id,
		is_correct,
		mission_title,
		event_title,
		mission_outcome_text,
		artifact,
		hint_used
	)

	if is_correct:
		var first_time_task_completed: bool = AppState.complete_task(task_id)
		if first_time_task_completed:
			awarded_score = _calculate_awarded_score(points)
			AppState.add_score(awarded_score)

		if is_final_task:
			AppState.complete_level(AppState.selected_level, ContentRepository.get_max_level())
			level_completed_now = true

		if message.is_empty():
			message = "Узел восстановлен. +%d очков." % [awarded_score]
		elif awarded_score > 0:
			message += " +%d очков." % [awarded_score]
		else:
			message += " Этот узел уже был очищен, очки повторно не начислены."

		if hint_used and awarded_score > 0:
			message += " Подсказка помогла, но снизила награду."
		if not is_final_task:
			message += " Открыт следующий узел сектора."
		AudioManager.play_success()
	else:
		AppState.add_mistake()
		AudioManager.play_error()
		if message.is_empty():
			message = "Команда отклонена. Узел не очищен."

	AppState.set_last_result(
		is_correct,
		explanation,
		str(task.get("question", "")),
		awarded_score,
		level_completed_now,
		task_id,
		AppState.selected_task_index,
		task_count
	)
	result_label.text = _build_result_panel_text(message, explanation, mission_result, mission_outcome_text)
	result_button.text = "Далее" if is_correct else "К разбору"
	mission_state_label.text = MissionService.get_event_status(AppState.selected_level, AppState.selected_task_index, task_count)
	mission_inventory_label.text = MissionService.get_inventory_text()
	_save_and_lock_task()

func _calculate_awarded_score(points: int) -> int:
	if not hint_used:
		return points
	return maxi(1, int(round(float(points) * 0.6)))

func _build_result_panel_text(message: String, explanation: String, mission_result: Dictionary, mission_outcome_text: String) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(message)
	lines.append("")
	lines.append("Игровое действие:")
	lines.append(mission_outcome_text)
	lines.append("Энергия: %s%d   Тревога: %s%d" % ["+" if int(mission_result.get("energy_delta", 0)) >= 0 else "", int(mission_result.get("energy_delta", 0)), "+" if int(mission_result.get("alarm_delta", 0)) >= 0 else "", int(mission_result.get("alarm_delta", 0))])
	if bool(mission_result.get("artifact_added", false)):
		lines.append("Получен артефакт: %s" % str(mission_result.get("artifact", "")))
	if bool(mission_result.get("emergency_reboot", false)):
		lines.append("Аварийная перезагрузка: энергия восстановлена до безопасного минимума, но тревога выросла.")
	lines.append("")
	lines.append("Разбор Python:")
	lines.append(explanation)
	return "\n".join(lines)

func _save_and_lock_task() -> void:
	SaveManager.save_game()
	result_panel.visible = true
	result_button.disabled = false

	for child in choice_list.get_children():
		var option: AnswerOption = child as AnswerOption
		if option != null:
			option.set_locked(true)

	for child in code_token_list.get_children():
		var token: CodeToken = child as CodeToken
		if token != null:
			token.set_locked(true)

	answer_input.editable = false
	check_input_button.disabled = true
	clear_code_button.disabled = true
	check_code_button.disabled = true
	code_input_panel.set_locked(true)

func _variant_to_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result: Array = []
	for item in value:
		result.append(item)
	return result

func _on_back_pressed() -> void:
	SceneRouter.go_to_lesson()

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_result_pressed() -> void:
	SceneRouter.go_to_result()
