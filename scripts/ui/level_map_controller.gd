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
	level_grid.columns = 2 if width_value >= 1180.0 else 1

func _build_level_cards() -> void:
	for child in level_grid.get_children():
		child.queue_free()

	for item in ContentRepository.get_lessons():
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var lesson: Dictionary = item
		var level: int = int(lesson.get("level", 1))
		var card: LevelCard = LEVEL_CARD_SCENE.instantiate() as LevelCard
		level_grid.add_child(card)
		card.setup(lesson, AppState.can_open_level(level), AppState.is_level_completed(level), ContentRepository.get_task_count_for_level(level), ContentRepository.get_completed_task_count_for_level(level))
		card.level_selected.connect(_on_level_selected)

	var lesson_count: int = ContentRepository.get_max_level()
	scroll_hint_label.text = "Прокрути вниз, чтобы увидеть все темы курса." if lesson_count > 6 else ""

func _update_progress_label() -> void:
	progress_label.text = "Очки: %d   Ошибки: %d   Пройдено уровней: %d/%d   Заданий: %d/%d" % [
		AppState.score,
		AppState.mistakes,
		AppState.completed_levels.size(),
		ContentRepository.get_max_level(),
		ContentRepository.get_completed_task_count(),
		ContentRepository.get_total_task_count()
	]

	story_label.text = "Курс PyQuest построен как длинная учебная кампания. Сначала открывай урок, затем проходи практику. Если остановишься на середине уровня, игра продолжит с первого невыполненного задания. Чем дальше ты продвигаешься, тем больше тем Python открывается - от базового print() до генераторов, декораторов и итоговой практики."
	final_button.disabled = false
	final_button.text = "Итоги"

func _on_level_selected(level: int) -> void:
	if AppState.select_level(level):
		AppState.clear_last_result()
		SceneRouter.go_to_lesson()

func _on_final_pressed() -> void:
	SceneRouter.go_to_final()

func _on_codex_pressed() -> void:
	SceneRouter.go_to_codex()

func _on_back_pressed() -> void:
	SceneRouter.go_to_main_menu()
