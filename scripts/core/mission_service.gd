extends Node

const MISSIONS_PATH: String = "res://data/missions.json"

var missions: Array = []

func _ready() -> void:
	reload()

func reload() -> void:
	missions = _load_json_array(MISSIONS_PATH)
	missions.sort_custom(func(a: Variant, b: Variant) -> bool:
		var mission_a: Dictionary = _to_dictionary(a)
		var mission_b: Dictionary = _to_dictionary(b)
		return int(mission_a.get("level", 0)) < int(mission_b.get("level", 0))
	)

func get_mission(level: int) -> Dictionary:
	for item in missions:
		var mission: Dictionary = _to_dictionary(item)
		if int(mission.get("level", 0)) == level:
			return mission
	return _missing_mission(level)

func get_event(level: int, task_index: int) -> Dictionary:
	var mission: Dictionary = get_mission(level)
	var events: Array = _variant_to_array(mission.get("events", []))
	if events.is_empty():
		return _missing_event(task_index)
	var safe_index: int = clampi(task_index, 0, events.size() - 1)
	return _to_dictionary(events[safe_index])

func get_sector_name(level: int) -> String:
	return str(get_mission(level).get("sector_name", "Сектор %d" % [level]))

func get_mission_title(level: int) -> String:
	return str(get_mission(level).get("title", "Миссия %d" % [level]))

func get_mission_briefing(level: int) -> String:
	var mission: Dictionary = get_mission(level)
	return "%s\n\nЦель: %s\nНаграда: %s" % [
		str(mission.get("briefing", "")),
		str(mission.get("objective", "")),
		str(mission.get("reward", ""))
	]

func get_event_title(level: int, task_index: int) -> String:
	return str(get_event(level, task_index).get("title", "Игровое действие"))

func get_event_brief(level: int, task_index: int, task: Dictionary = {}) -> String:
	var event: Dictionary = get_event(level, task_index)
	var context: String = str(task.get("mission_context", ""))
	if context.is_empty():
		context = str(event.get("interaction", "Выполнить действие в терминале уровня."))
	return context

func get_event_status(level: int, task_index: int, task_count: int) -> String:
	var event: Dictionary = get_event(level, task_index)
	var mission_progress: int = AppState.get_completed_mission_step_count_for_level(level)
	return "Узел %d/%d · Риск: %s · Очищено узлов: %d/%d · Энергия: %d/%d · Тревога: %d%%" % [
		task_index + 1,
		maxi(1, task_count),
		str(event.get("risk", "средний")),
		mission_progress,
		maxi(1, task_count),
		AppState.player_energy,
		AppState.max_player_energy,
		AppState.system_alarm
	]

func get_inventory_text() -> String:
	if AppState.collected_artifacts.is_empty():
		return "Инвентарь: пока пусто"
	var total_count: int = AppState.collected_artifacts.size()
	var preview: PackedStringArray = PackedStringArray()
	var start_index: int = maxi(0, total_count - 3)
	for index in range(start_index, total_count):
		preview.append(str(AppState.collected_artifacts[index]))
	var extra_text: String = ""
	if total_count > 3:
		extra_text = "  + ещё %d" % [total_count - 3]
	return "Инвентарь: %s%s" % [", ".join(preview), extra_text]

func build_outcome_text(level: int, task_index: int, is_correct: bool, task: Dictionary = {}) -> String:
	var event: Dictionary = get_event(level, task_index)
	if is_correct:
		return str(task.get("mission_success", event.get("success", "Узел уровня восстановлен.")))
	return str(task.get("mission_failure", event.get("failure", "Система получила неверную команду.")))

func get_level_map_status(level: int, task_count: int) -> String:
	var repaired_count: int = AppState.get_completed_mission_step_count_for_level(level)
	var sector_name: String = get_sector_name(level)
	return "%s · узлы %d/%d" % [sector_name, repaired_count, maxi(1, task_count)]

func get_campaign_summary() -> String:
	var max_level: int = ContentRepository.get_max_level()
	var restored_sectors: int = AppState.completed_levels.size()
	return "Сектора: %d/%d · Энергия: %d/%d · Тревога: %d%% · Артефакты: %d" % [
		restored_sectors,
		max_level,
		AppState.player_energy,
		AppState.max_player_energy,
		AppState.system_alarm,
		AppState.collected_artifacts.size()
	]

func get_rank_title() -> String:
	var completed_tasks: int = ContentRepository.get_completed_task_count()
	var total_tasks: int = maxi(1, ContentRepository.get_total_task_count())
	var completion_ratio: float = float(completed_tasks) / float(total_tasks)
	if completion_ratio >= 1.0 and AppState.mistakes <= 10 and AppState.system_alarm <= 20:
		return "S — архитектор чистого кода"
	if completion_ratio >= 0.8 and AppState.system_alarm <= 45:
		return "A — уверенный отладчик"
	if completion_ratio >= 0.5:
		return "B — стажёр ядра PyQuest"
	return "C — курсант цифрового мира"

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

func _to_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary_value: Dictionary = value
		return dictionary_value
	return {}

func _variant_to_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result: Array = []
	for item in value:
		result.append(item)
	return result

func _missing_mission(level: int) -> Dictionary:
	return {
		"level": level,
		"sector_name": "Сектор %d" % [level],
		"title": "Миссия %d" % [level],
		"objective": "Пройти задания уровня.",
		"briefing": "Для этого уровня пока не задано отдельное описание миссии.",
		"reward": "Ключ доступа",
		"events": []
	}

func _missing_event(task_index: int) -> Dictionary:
	return {
		"order": task_index + 1,
		"title": "Игровое действие",
		"interaction": "Выполнить действие в учебном терминале.",
		"artifact": "Фрагмент кода",
		"success": "Узел восстановлен.",
		"failure": "Команда отклонена.",
		"risk": "средний"
	}
