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
		title_label.text = "Задание выполнено"
	else:
		title_label.text = "Задание не пройдено"

	var task_text: String = "Задание: %d/%d" % [AppState.last_task_index + 1, AppState.last_task_count]
	var level_status: String = "Уровень завершён" if AppState.last_level_completed else "Уровень ещё продолжается"
	if not AppState.last_answer_correct:
		level_status = "Вернись к заданию и попробуй ещё раз"

	summary_label.text = "Уровень: %d\n%s\nСтатус: %s\nНачислено за ответ: %d\nВсего очков: %d\nОшибки: %d\nЗаданий пройдено: %d/%d" % [
		AppState.selected_level,
		task_text,
		level_status,
		AppState.last_awarded_score,
		AppState.score,
		AppState.mistakes,
		ContentRepository.get_completed_task_count(),
		ContentRepository.get_total_task_count()
	]

	explanation_label.text = AppState.last_explanation
	retry_button.disabled = AppState.last_answer_correct

	if not AppState.last_answer_correct:
		next_button.disabled = true
		next_button.text = "Сначала исправь ответ"
	elif ContentRepository.has_next_task(AppState.selected_level, AppState.last_task_index):
		next_button.disabled = false
		next_button.text = "Следующее задание"
	elif AppState.selected_level >= ContentRepository.get_max_level():
		next_button.disabled = false
		next_button.text = "Итог прохождения"
	else:
		next_button.disabled = false
		next_button.text = "Следующий уровень"

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
