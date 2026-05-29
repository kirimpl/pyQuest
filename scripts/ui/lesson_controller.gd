extends Control

@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var objectives_label: Label = %ObjectivesLabel
@onready var example_console: PythonConsole = %ExampleConsole as PythonConsole
@onready var back_button: Button = %BackButton
@onready var task_button: Button = %TaskButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	task_button.pressed.connect(_on_task_pressed)
	_show_lesson()

func _show_lesson() -> void:
	var lesson: Dictionary = ContentRepository.get_lesson(AppState.selected_level)
	title_label.text = "Урок %d. %s" % [AppState.selected_level, str(lesson.get("title", "Тема"))]
	body_label.text = str(lesson.get("text", ""))
	objectives_label.text = _build_objectives_text(lesson)

	example_console.setup_example(lesson)

	var task_count: int = ContentRepository.get_task_count_for_level(AppState.selected_level)
	var completed_count: int = ContentRepository.get_completed_task_count_for_level(AppState.selected_level)
	var first_incomplete_index: int = ContentRepository.get_first_incomplete_task_index_for_level(AppState.selected_level)
	if completed_count >= task_count and task_count > 0:
		task_button.text = "Повторить задания уровня (%d/%d)" % [completed_count, task_count]
	else:
		task_button.text = "Продолжить с задания %d/%d" % [first_incomplete_index + 1, task_count]

func _build_objectives_text(lesson: Dictionary) -> String:
	var objectives: Array = _variant_to_array(lesson.get("objectives", []))
	if objectives.is_empty():
		return "После урока нужно решить задания по теме и закрепить синтаксис на практике."

	var lines: PackedStringArray = PackedStringArray()
	lines.append("Что нужно понять в этом уроке:")
	for item in objectives:
		lines.append("- " + str(item))
	return "\n".join(lines)

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
