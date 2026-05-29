extends Control

@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var conclusion_label: Label = %ConclusionLabel
@onready var achievements_label: Label = %AchievementsLabel
@onready var map_button: Button = %MapButton
@onready var menu_button: Button = %MenuButton
@onready var restart_button: Button = %RestartButton

func _ready() -> void:
	map_button.pressed.connect(_on_map_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	_show_final()

func _show_final() -> void:
	var max_level: int = ContentRepository.get_max_level()
	var completed_levels: int = AppState.completed_levels.size()
	var completed_tasks: int = ContentRepository.get_completed_task_count()
	var total_tasks: int = ContentRepository.get_total_task_count()
	var is_complete: bool = completed_levels >= max_level and completed_tasks >= total_tasks

	title_label.text = "PyQuest пройден" if is_complete else "Итоги обучения"
	summary_label.text = "Уровней пройдено: %d/%d\nЗаданий выполнено: %d/%d\nОчки: %d\nОшибки: %d" % [
		completed_levels,
		max_level,
		completed_tasks,
		total_tasks,
		AppState.score,
		AppState.mistakes
	]

	achievements_label.text = _build_achievements_text(completed_tasks, total_tasks, completed_levels, max_level)

	if is_complete:
		conclusion_label.text = "Ты прошёл полный маршрут PyQuest: от первых строк Python до API, JSON, тестирования, dataclass, async/await, SQLite и финального мини-проекта. Это уже не просто база, а цельная практическая траектория для самостоятельного старта в программировании."
	else:
		conclusion_label.text = "Обучение ещё не завершено. Вернись на карту уровней и продолжи прохождение открытых тем."

func _build_achievements_text(completed_tasks: int, total_tasks: int, completed_levels: int, max_level: int) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Достижения:")
	lines.append(("✓" if completed_tasks >= 1 else "○") + " Первый запуск кода")
	lines.append(("✓" if completed_levels >= 3 else "○") + " Первые три темы")
	var half_tasks: int = int(ceil(float(total_tasks) / 2.0))
	lines.append(("✓" if completed_tasks >= half_tasks else "○") + " Половина практики")
	lines.append(("✓" if completed_levels >= 10 else "○") + " Уверенная база Python")
	lines.append(("✓" if completed_levels >= 20 else "○") + " Продвинутый синтаксис и ООП")
	lines.append(("✓" if completed_levels >= 30 else "○") + " Инструменты реальной разработки")
	lines.append(("✓" if completed_levels >= max_level else "○") + " Завершение полного маршрута")
	lines.append(("✓" if AppState.mistakes <= 10 and completed_tasks >= total_tasks else "○") + " Аккуратный код: не более 10 ошибок за весь курс")
	return "\n".join(lines)

func _on_map_pressed() -> void:
	SceneRouter.go_to_level_map()

func _on_menu_pressed() -> void:
	SceneRouter.go_to_main_menu()

func _on_restart_pressed() -> void:
	AppState.start_new_game()
	SaveManager.save_game()
	SceneRouter.go_to_level_map()
