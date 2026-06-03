extends Control

const LEVEL_CARD_SCENE: PackedScene = preload("res://scenes/components/LevelCard.tscn")

@onready var level_grid: GridContainer = %LevelGrid
@onready var progress_label: Label = %ProgressLabel
@onready var story_label: Label = %StoryLabel
@onready var scroll_hint_label: Label = %ScrollHintLabel
@onready var levels_scroll: ScrollContainer = %LevelsScroll
@onready var back_button: Button = %BackButton
@onready var final_button: Button = %FinalButton
@onready var codex_button: Button = %CodexButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	final_button.pressed.connect(_on_final_pressed)
	codex_button.pressed.connect(_on_codex_pressed)
	_setup_scrollbar()
	_update_grid_columns()
	_build_level_cards()
	_update_progress_label()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_grid_columns()

func _setup_scrollbar() -> void:
	if levels_scroll == null:
		return
	var v_scroll_bar: VScrollBar = levels_scroll.get_v_scroll_bar()
	if v_scroll_bar != null:
		v_scroll_bar.custom_minimum_size = Vector2(16, 0)
		v_scroll_bar.show()

func _update_grid_columns() -> void:
	if level_grid == null:
		return
	var width_value: float = size.x if size.x > 0.0 else get_viewport_rect().size.x
	if width_value >= 1760.0:
		level_grid.columns = 4
	elif width_value >= 1280.0:
		level_grid.columns = 3
	elif width_value >= 900.0:
		level_grid.columns = 2
	else:
		level_grid.columns = 1

func _build_level_cards() -> void:
	for child in level_grid.get_children():
		child.free()

	var chapter_totals: Dictionary = _get_chapter_totals()
	var chapter_completed: Dictionary = _get_chapter_completed_counts()
	for level_number in range(1, CodeWorldService.get_level_count() + 1):
		var level_data: Dictionary = CodeWorldService.get_level(level_number)
		var chapter: String = str(level_data.get("chapter", "Кампания"))
		var card: LevelCard = LEVEL_CARD_SCENE.instantiate() as LevelCard
		level_grid.add_child(card)
		card.setup(level_data, AppState.can_open_level(level_number), AppState.is_level_completed(level_number), int(chapter_totals.get(chapter, 1)), int(chapter_completed.get(chapter, 0)))
		card.level_selected.connect(_on_level_selected)

	scroll_hint_label.text = "35 программируемых секторов · финальный сектор выделен отдельно."

func _get_chapter_totals() -> Dictionary:
	var totals: Dictionary = {}
	for level_number in range(1, CodeWorldService.get_level_count() + 1):
		var level_data: Dictionary = CodeWorldService.get_level(level_number)
		var chapter: String = str(level_data.get("chapter", "Кампания"))
		totals[chapter] = int(totals.get(chapter, 0)) + 1
	return totals

func _get_chapter_completed_counts() -> Dictionary:
	var completed: Dictionary = {}
	for level_number in range(1, CodeWorldService.get_level_count() + 1):
		var level_data: Dictionary = CodeWorldService.get_level(level_number)
		var chapter: String = str(level_data.get("chapter", "Кампания"))
		if not completed.has(chapter):
			completed[chapter] = 0
		if AppState.is_level_completed(level_number):
			completed[chapter] = int(completed.get(chapter, 0)) + 1
	return completed

func _update_progress_label() -> void:
	progress_label.text = "Code Adventure · Пройдено: %d/%d · Звёзды: %d/%d · Очки: %d · Ошибки: %d · Запусков кода: %d" % [
		AppState.completed_levels.size(),
		CodeWorldService.get_level_count(),
		AppState.get_total_code_stars(),
		CodeWorldService.get_level_count() * 3,
		AppState.score,
		AppState.mistakes,
		AppState.get_total_code_attempts()
	]

	story_label.text = "Выбери открытый сектор, составь программу героя и восстанови узел. Результат оценивается звёздами за эффективность маршрута."
	final_button.disabled = false
	final_button.text = "Итоги кампании"

func _on_level_selected(level: int) -> void:
	if AppState.select_level(level):
		AppState.clear_last_result()
		SceneRouter.go_to_code_game()

func _on_final_pressed() -> void:
	SceneRouter.go_to_final()

func _on_codex_pressed() -> void:
	SceneRouter.go_to_codex()

func _on_back_pressed() -> void:
	SceneRouter.go_to_main_menu()
