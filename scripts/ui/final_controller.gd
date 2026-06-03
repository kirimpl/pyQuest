extends Control

@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var conclusion_label: Label = %ConclusionLabel
@onready var achievements_label: Label = %AchievementsLabel
@onready var map_button: Button = %MapButton
@onready var menu_button: Button = %MenuButton
@onready var restart_button: Button = %RestartButton

func _ready() -> void:
	map_button.text = "Карта кампании"
	menu_button.text = "Главное меню"
	restart_button.text = "Начать заново"
	map_button.pressed.connect(_on_map_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	_show_final()

func _show_final() -> void:
	var max_level: int = CodeWorldService.get_level_count()
	var completed_levels: int = AppState.completed_levels.size()
	var is_complete: bool = completed_levels >= max_level
	var attempts: int = AppState.get_total_code_attempts()
	var total_stars: int = AppState.get_total_code_stars()
	var rank_title: String = _get_code_rank(completed_levels, max_level, attempts, AppState.mistakes)

	title_label.text = "Ядро PyQuest восстановлено" if is_complete else "Итоги Code Adventure"
	summary_label.text = "Восстановлено секторов: %d/%d\nЗвёзды кампании: %d/%d\nЗапусков кода: %d\nОчки: %d\nОшибки запуска: %d\nОткрыт сектор: %d\nИтоговый ранг: %s" % [
		completed_levels,
		max_level,
		total_stars,
		max_level * 3,
		attempts,
		AppState.score,
		AppState.mistakes,
		AppState.max_unlocked_level,
		rank_title
	]

	achievements_label.text = _build_achievements_text(completed_levels, max_level, attempts, total_stars)
	if is_complete:
		conclusion_label.text = "Финальная миссия завершена: игрок написал программу, использовал функцию, цикл и условие, собрал ключи и кристаллы, открыл шлюзы, активировал терминалы и устранил баги. Это итоговый экран кампании, который можно показывать после прохождения 35-го сектора."
	else:
		conclusion_label.text = "Кампания ещё не завершена. Вернись на карту, выбери открытый сектор и восстанови финальное ядро."

func _get_code_rank(completed_levels: int, max_level: int, attempts: int, mistakes: int) -> String:
	if completed_levels >= max_level and AppState.get_total_code_stars() >= max_level * 3 and mistakes <= 5:
		return "S+ - мастер чистого маршрута"
	if completed_levels >= max_level and mistakes <= 5:
		return "S - архитектор кода"
	if completed_levels >= max_level:
		return "A - кампания завершена"
	if completed_levels >= int(max_level * 0.7):
		return "B - уверенный разработчик"
	if completed_levels >= int(max_level * 0.35):
		return "C - стажёр цифрового мира"
	if attempts > 0:
		return "D - начало пути"
	return "Нет данных"

func _build_achievements_text(completed_levels: int, max_level: int, attempts: int, total_stars: int) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Достижения Code Adventure:")
	lines.append(_mark(completed_levels >= 1) + " Первый сектор восстановлен")
	lines.append(_mark(completed_levels >= 5) + " Освоены базовые команды героя")
	lines.append(_mark(completed_levels >= 10) + " Использованы переменные, списки и циклы")
	lines.append(_mark(completed_levels >= 15) + " Кампания дошла до функций")
	lines.append(_mark(completed_levels >= 22) + " Используются условия и while-маршруты")
	lines.append(_mark(completed_levels >= 30) + " Финальные сектора решаются структурным кодом")
	lines.append(_mark(completed_levels >= max_level) + " Финальное ядро стабилизировано")
	lines.append(_mark(total_stars >= max_level * 2) + " Собрано не менее двух третей звёзд кампании")
	lines.append(_mark(total_stars >= max_level * 3) + " Идеальная кампания: три звезды в каждом секторе")
	lines.append(_mark(AppState.mistakes <= 10 and completed_levels >= max_level) + " Аккуратное прохождение: не более 10 ошибок")
	lines.append(_mark(attempts <= max_level * 2 and completed_levels >= max_level) + " Эффективное прохождение: минимум лишних запусков")
	return "\n".join(lines)

func _mark(done: bool) -> String:
	return "✓" if done else "○"

func _on_map_pressed() -> void:
	SceneRouter.go_to_level_map()

func _on_menu_pressed() -> void:
	SceneRouter.go_to_main_menu()

func _on_restart_pressed() -> void:
	AppState.start_new_game()
	SaveManager.save_game()
	SceneRouter.go_to_code_game()
