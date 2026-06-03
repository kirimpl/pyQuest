extends Control

@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var explanation_label: Label = %ExplanationLabel
@onready var map_button: Button = %MapButton
@onready var retry_button: Button = %RetryButton
@onready var next_button: Button = %NextButton
@onready var menu_button: Button = %MenuButton

func _ready() -> void:
	map_button.pressed.connect(_on_map_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	next_button.pressed.connect(_on_next_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	_show_result()

func _show_result() -> void:
	if AppState.last_answer_correct:
		title_label.text = "Узел сектора восстановлен"
	else:
		title_label.text = "Команда терминала отклонена"

	var task_text: String = "Узел: %d/%d" % [AppState.last_task_index + 1, AppState.last_task_count]
	var level_status: String = "Сектор очищен" if AppState.last_level_completed else "Сектор ещё нестабилен"
	if not AppState.last_answer_correct:
		level_status = "Нужно вернуться и исправить действие"

	summary_label.text = "%s\n%s\nСтатус: %s\nСобытие: %s\nЭнергия: %d/%d (%s)\nТревога: %d%% (%s)\nНачислено за действие: %d\nВсего очков: %d\nОшибки: %d\nАртефактов: %d" % [
		AppState.last_mission_title,
		task_text,
		level_status,
		AppState.last_mission_event,
		AppState.player_energy,
		AppState.max_player_energy,
		_format_delta(AppState.last_energy_delta),
		AppState.system_alarm,
		_format_delta(AppState.last_alarm_delta),
		AppState.last_awarded_score,
		AppState.score,
		AppState.mistakes,
		AppState.collected_artifacts.size()
	]

	explanation_label.text = _build_explanation_text()
	retry_button.disabled = AppState.last_answer_correct

	if not AppState.last_answer_correct:
		next_button.disabled = true
		next_button.text = "Сначала исправь узел"
	elif ContentRepository.has_next_task(AppState.selected_level, AppState.last_task_index):
		next_button.disabled = false
		next_button.text = "Следующий узел"
	elif AppState.selected_level >= ContentRepository.get_max_level():
		next_button.disabled = false
		next_button.text = "Итог кампании"
	else:
		next_button.disabled = false
		next_button.text = "Следующий сектор"

func _format_delta(value: int) -> String:
	if value >= 0:
		return "+%d" % [value]
	return str(value)

func _build_explanation_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Игровой результат:")
	lines.append(AppState.last_mission_outcome)
	if not AppState.last_artifact.is_empty():
		lines.append("Получен артефакт: %s" % AppState.last_artifact)
	if AppState.last_hint_used:
		lines.append("Использована подсказка: награда за узел снижена.")
	if AppState.last_emergency_reboot:
		lines.append("Была выполнена аварийная перезагрузка из-за нулевой энергии.")
	lines.append("")
	lines.append("Разбор Python:")
	lines.append(AppState.last_explanation)
	return "\n".join(lines)

func _on_map_pressed() -> void:
	SceneRouter.go_to_level_map()

func _on_retry_pressed() -> void:
	SceneRouter.go_to_task()

func _on_next_pressed() -> void:
	if not AppState.last_answer_correct:
		return

	if ContentRepository.has_next_task(AppState.selected_level, AppState.last_task_index):
		AppState.select_task_index(AppState.last_task_index + 1)
		AppState.clear_last_result()
		SaveManager.save_game()
		SceneRouter.go_to_task()
		return

	if AppState.selected_level >= ContentRepository.get_max_level():
		AppState.clear_last_result()
		SaveManager.save_game()
		SceneRouter.go_to_final()
		return

	var next_level: int = AppState.selected_level + 1
	if AppState.select_level(next_level):
		AppState.clear_last_result()
		SaveManager.save_game()
		SceneRouter.go_to_lesson()

func _on_menu_pressed() -> void:
	SceneRouter.go_to_main_menu()
