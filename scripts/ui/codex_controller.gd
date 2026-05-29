extends Control

const CODEX_TOPIC_SCENE: PackedScene = preload("res://scenes/components/CodexTopic.tscn")

@onready var topic_list: VBoxContainer = %TopicList
@onready var title_label: Label = %TitleLabel
@onready var progress_label: Label = %ProgressLabel
@onready var body_label: Label = %BodyLabel
@onready var objectives_label: Label = %ObjectivesLabel
@onready var example_console: PythonConsole = %ExampleConsole as PythonConsole
@onready var map_button: Button = %MapButton
@onready var menu_button: Button = %MenuButton

var selected_level: int = 1

func _ready() -> void:
	map_button.pressed.connect(_on_map_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	_build_topics()
	_select_initial_topic()

func _build_topics() -> void:
	for child in topic_list.get_children():
		child.queue_free()

	for item in ContentRepository.get_lessons():
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var lesson: Dictionary = item
		var level: int = int(lesson.get("level", 1))
		var topic: CodexTopic = CODEX_TOPIC_SCENE.instantiate() as CodexTopic
		topic_list.add_child(topic)
		topic.setup(
			lesson,
			AppState.can_open_level(level),
			ContentRepository.get_completed_task_count_for_level(level),
			ContentRepository.get_task_count_for_level(level)
		)
		topic.topic_selected.connect(_on_topic_selected)

func _select_initial_topic() -> void:
	selected_level = clampi(AppState.selected_level, 1, ContentRepository.get_max_level())
	if not AppState.can_open_level(selected_level):
		selected_level = 1
	_show_topic(selected_level)

func _show_topic(level: int) -> void:
	selected_level = level
	var lesson: Dictionary = ContentRepository.get_lesson(level)
	var completed_tasks: int = ContentRepository.get_completed_task_count_for_level(level)
	var total_tasks: int = maxi(1, ContentRepository.get_task_count_for_level(level))

	title_label.text = "Справочник: урок %d - %s" % [level, str(lesson.get("title", "Тема"))]
	progress_label.text = "Прогресс по теме: %d/%d заданий. Открытый уровень: %d." % [completed_tasks, total_tasks, AppState.max_unlocked_level]
	body_label.text = str(lesson.get("text", ""))
	objectives_label.text = _build_objectives_text(lesson)
	example_console.setup_example(lesson)

func _build_objectives_text(lesson: Dictionary) -> String:
	var objectives: Array = _variant_to_array(lesson.get("objectives", []))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Коротко по теме:")
	if objectives.is_empty():
		lines.append("• повтори синтаксис урока")
		lines.append("• открой пример кода и проверь вывод")
	else:
		for item in objectives:
			lines.append("• " + str(item))
	return "\n".join(lines)

func _variant_to_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result: Array = []
	for item in value:
		result.append(item)
	return result

func _on_topic_selected(level: int) -> void:
	_show_topic(level)

func _on_map_pressed() -> void:
	SceneRouter.go_to_level_map()

func _on_menu_pressed() -> void:
	SceneRouter.go_to_main_menu()
