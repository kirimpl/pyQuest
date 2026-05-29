extends Node

const LESSONS_PATH: String = "res://data/lessons.json"
const TASKS_PATH: String = "res://data/tasks.json"

var lessons: Array = []
var tasks: Array = []

func _ready() -> void:
	reload()

func reload() -> void:
	lessons = _load_json_array(LESSONS_PATH)
	tasks = _load_json_array(TASKS_PATH)
	_sort_content()

func _load_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Файл не найден: " + path)
		return []

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть файл: " + path)
		return []

	var parsed_data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_data) != TYPE_ARRAY:
		push_error("JSON должен содержать массив: " + path)
		return []

	var result: Array = []
	for item in parsed_data:
		result.append(item)
	return result

func _sort_content() -> void:
	lessons.sort_custom(func(a: Variant, b: Variant) -> bool:
		var lesson_a: Dictionary = _to_dictionary(a)
		var lesson_b: Dictionary = _to_dictionary(b)
		return int(lesson_a.get("level", 0)) < int(lesson_b.get("level", 0))
	)
	tasks.sort_custom(func(a: Variant, b: Variant) -> bool:
		var task_a: Dictionary = _to_dictionary(a)
		var task_b: Dictionary = _to_dictionary(b)
		var level_a: int = int(task_a.get("level", 0))
		var level_b: int = int(task_b.get("level", 0))
		if level_a == level_b:
			var order_a: int = int(task_a.get("order", task_a.get("id", 0)))
			var order_b: int = int(task_b.get("order", task_b.get("id", 0)))
			return order_a < order_b
		return level_a < level_b
	)

func get_lessons() -> Array:
	return lessons

func get_lesson(level: int) -> Dictionary:
	for item in lessons:
		var lesson: Dictionary = _to_dictionary(item)
		if int(lesson.get("level", 0)) == level:
			return lesson

	return _missing_lesson(level)

func get_tasks_for_level(level: int) -> Array:
	var result: Array = []
	for item in tasks:
		var task: Dictionary = _to_dictionary(item)
		if int(task.get("level", 0)) == level:
			result.append(task)
	return result

func get_task_count_for_level(level: int) -> int:
	return get_tasks_for_level(level).size()


func get_first_incomplete_task_index_for_level(level: int) -> int:
	var level_tasks: Array = get_tasks_for_level(level)
	if level_tasks.is_empty():
		return 0

	for index in range(level_tasks.size()):
		var task: Dictionary = _to_dictionary(level_tasks[index])
		if not AppState.is_task_completed(int(task.get("id", -1))):
			return index

	return 0

func get_level_progress_text(level: int) -> String:
	var completed_count: int = get_completed_task_count_for_level(level)
	var total_count: int = maxi(1, get_task_count_for_level(level))
	return "%d/%d" % [completed_count, total_count]

func get_task_for_level(level: int, task_index: int = 0) -> Dictionary:
	var level_tasks: Array = get_tasks_for_level(level)
	if level_tasks.is_empty():
		return _missing_task(level)

	var safe_index: int = clampi(task_index, 0, level_tasks.size() - 1)
	return _to_dictionary(level_tasks[safe_index])

func has_next_task(level: int, task_index: int) -> bool:
	return task_index + 1 < get_task_count_for_level(level)

func get_total_task_count() -> int:
	return tasks.size()

func get_completed_task_count_for_level(level: int) -> int:
	var count: int = 0
	for item in get_tasks_for_level(level):
		var task: Dictionary = _to_dictionary(item)
		if AppState.is_task_completed(int(task.get("id", -1))):
			count += 1
	return count


func get_completed_task_count() -> int:
	var count: int = 0
	for item in tasks:
		var task: Dictionary = _to_dictionary(item)
		if AppState.is_task_completed(int(task.get("id", -1))):
			count += 1
	return count

func get_max_level() -> int:
	var max_level: int = 1
	for item in lessons:
		var lesson: Dictionary = _to_dictionary(item)
		max_level = maxi(max_level, int(lesson.get("level", 1)))
	return max_level

func _to_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary_value: Dictionary = value
		return dictionary_value
	return {}

func _missing_lesson(level: int) -> Dictionary:
	return {
		"level": level,
		"title": "Урок не найден",
		"text": "Для выбранного уровня пока нет теоретического материала.",
		"code": ""
	}

func _missing_task(level: int) -> Dictionary:
	return {
		"id": -1,
		"level": level,
		"type": "single_choice",
		"question": "Задание для выбранного уровня не найдено.",
		"answers": ["Вернуться на карту"],
		"correct": 0,
		"score": 0,
		"explanation": "Добавьте задание в файл res://data/tasks.json."
	}
