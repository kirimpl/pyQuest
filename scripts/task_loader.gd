extends Node
class_name TaskLoader

const LESSONS_PATH := "res://data/lessons.json"
const TASKS_PATH := "res://data/tasks.json"

static func _load_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Файл не найден: " + path)
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть файл: " + path)
		return []

	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_ARRAY:
		push_error("JSON должен содержать массив: " + path)
		return []

	return data

static func get_lessons() -> Array:
	return _load_json_array(LESSONS_PATH)

static func get_tasks() -> Array:
	return _load_json_array(TASKS_PATH)

static func get_lesson(level: int) -> Dictionary:
	for lesson in get_lessons():
		if typeof(lesson) == TYPE_DICTIONARY and int(lesson.get("level", 0)) == level:
			return lesson

	return {
		"level": level,
		"title": "Урок не найден",
		"text": "Для выбранного уровня пока нет теоретического материала.",
		"code": ""
	}

static func get_first_task_for_level(level: int) -> Dictionary:
	for task in get_tasks():
		if typeof(task) == TYPE_DICTIONARY and int(task.get("level", 0)) == level:
			return task

	return {
		"id": -1,
		"level": level,
		"type": "single_choice",
		"question": "Задание для выбранного уровня не найдено.",
		"answers": ["Вернуться на карту"],
		"correct": 0,
		"explanation": "Добавьте задание в файл res://data/tasks.json."
	}

static func get_max_level() -> int:
	var max_level := 1
	for lesson in get_lessons():
		if typeof(lesson) == TYPE_DICTIONARY:
			max_level = max(max_level, int(lesson.get("level", 1)))
	return max_level
